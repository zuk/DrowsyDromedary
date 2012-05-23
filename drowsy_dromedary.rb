require 'grape'
require 'mongo'
require 'yaml'
require 'json'

class DrowsyDromedary < Grape::API
  version 'v1', :using => :header #, :vendor => 'mongodb'

  error_format :json
  #default_format :json
  format :json

  def initialize
    super
    @dbs ||= {}
    File.open("config.yml") do |f|
      @config = YAML.load(f)
    end
  end

  helpers do
    # def current_user
    #   @current_user ||= User.authorize!(env)
    # end

    # def authenticate!
    #   error!('401 Unauthorized', 401) unless current_user
    # end

    def connect
      @connection ||= Mongo::Connection.new
    end

    def create_db(db)
      @dbs ||= {}
      @dbs[db] = connect.db(db, :strict => true)
      @dbs[db].collection_names # calling .collection_names seems to create the database
      @dbs[db]
    end

    def connect_to_db(db)
      @dbs ||= {}
      return @dbs[db] if @dbs[db]
      c = connect
      if c.database_names.include?(db.to_s)
        c.db(db, :strict => true)
      else
        return false
      end
    end

    def check_required_params(required)
      required = [required] unless required.kind_of?(Array)
      required = required.collect{|r| r.to_s}
      missing = required - ((params.keys - @env["rack.routing_args"].keys) & required)
      unless missing.empty?
        error!(["The following parameters are required for this request but were missing: ", missing], 400)
      end
    end

    def extract_data_from_params
      # TODO: if data type is JSON, JSON.parse(@env["rack.request.form_vars"]) instead.
      data = params.dup
      @env["rack.routing_args"].keys.each do |key|
        data.delete(key)
      end
      data
    end

    def extract_selector_from_params
      if params[:selector]
        selector = JSON.parse(params[:selector])
        selector
      else
        nil
      end
    end

    def extract_sort_from_params
      if params[:sort]
        sort = nil
        begin
          sort = JSON.parse(params[:sort])
        rescue JSON::ParserError
          sort = params[:sort]
        end
        sort
      else
        nil
      end
    end
  end

  get '/' do
    connect.database_names
  end

  post '/' do
    check_required_params(:db)
    
    db = create_db(params[:db])
    if db 
      status 201
      db.collection_names
    else
      error!("Database #{params[:db].inspect} was not created.", 500)
    end
  end

  # TODO: implement DELETE to drop database (or maybe not? too risky?)

  resource '/:db' do
    before do
      @db = connect_to_db(params[:db])
      unless @db
        error!("There is no database named #{params[:db].inspect}!", 404)
      end
    end

    get do
      @db.collection_names
    end

    post do
      check_required_params(:collection)
      
      coll = @db.create_collection(params[:collection])
      if coll 
        redirect "/#{params[:db]}/#{params[:collection]}", :status => 201
        status 201
      else
        error!("Database #{params[:db].inspect} was not created.", 500)
      end
    end

    # TODO: implement DELETE to drop collection

    resource '/:collection' do
      desc "Retrieve all items in the collection"
      get do
        selector = extract_selector_from_params
        sort = extract_sort_from_params
        @db.collection(params[:collection]).find(selector, :sort => sort).to_a
      end

      desc "Add a new item to the collection"
      post do
        data = extract_data_from_params
        id = @db.collection(params[:collection]).save(data)
        # FIXME: save ourselves the extra query and just return `data`?
        @db.collection(params[:collection]).find_one(id)
      end

      # TODO: implement DELETE to allow mass deletion of items in collection

      desc "Retrieve the item with id :id from the collection"
      get '/:id' do
        id = BSON::ObjectId(params[:id])
        @db.collection(params[:collection]).find_one(id)
      end

      desc "Replace the item with id :id in the collection"
      put '/:id' do
        id = BSON::ObjectId(params[:id])
        data = extract_data_from_params

        @db.collection(params[:collection]).update(
          {'_id' => id},
          data
        )
        # FIXME: save ourselves the extra query and just return `data`?
        @db.collection(params[:collection]).find_one(id)
      end

      desc "Delete the item with id :id from the collection"
      delete '/:id' do
        id = BSON::ObjectId(params[:id])
        if @db.collection(params[:collection]).remove({'_id' => id})
          {} # FIXME: we probably want to just return nil (i.e. null) here, but this is not parsable by JSON.parse()
        else
          error!("Item #{params[:id].inspect} could not be deleted from #{params[:collection].inspect}!", 500)
        end
      end
    end
  end

end