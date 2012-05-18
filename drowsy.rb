require 'grape'
require 'mongo'
require 'yaml'
require 'json'
require 'ruby-debug'

class DrowsyDromedary < Grape::API
  version 'v1', :using => :header #, :vendor => 'mongodb'

  #error_format :json
  #default_format :json
  format :json

  def initialize
    super
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

    def connect_to_db(db)
      @mongo_connections ||= {}
      @mongo_connections[db] ||= Mongo::Connection.new.db(db)
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
        JSON.parse(params[:selector])
      else
        selector = params.dup
        @env["rack.routing_args"].keys.each do |key|
          selector.delete(key)
        end
        selector.to_hash
      end
    end
  end

  resource '/:db' do
    before do 
      @db = connect_to_db(params[:db])
    end

    get do
      @db.collection_names
    end

    resource '/:collection' do
      desc "Retrieve all items in the collection"
      get do
        selector = extract_selector_from_params
        @db.collection(params[:collection]).find(selector).to_a
      end

      desc "Add a new item to the collection"
      post do
        data = extract_data_from_params
        id = @db.collection(params[:collection]).save(data)
        # FIXME: save ourselves the extra query and just return `data`?
        @db.collection(params[:collection]).find_one(id)
      end

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
        @db.collection(params[:collection]).remove({'_id' => id})
      end
    end
  end

end