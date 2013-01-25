$: << File.dirname(__FILE__)

require 'drowsy_dromedary'

require 'rubygems'
require 'bundler'
Bundler.setup :default, :development

require 'rack/test'

require 'base64'
require 'cgi'

require 'mongo'

RSpec.configure do |config|
  config.include Rack::Test::Methods

  def app
    DrowsyDromedary
  end
end

$DB = "drowsy-test-#{rand(10e10).to_s(32)}"

describe DrowsyDromedary do
  before(:all) do
    @mongo = Mongo::Connection.new
    #puts "Creating test database #{$DB.inspect}..."
    @db = @mongo.db($DB)
    @db.collection_names # creates the $DB database
  end

  after(:all) do
    #puts "Dropping test database #{$DB.inspect}..."
    @mongo.drop_database($DB)
    @mongo.close
  end

  describe "/" do
    describe "GET" do
      it "returns a list of the available databases" do
        get "/"
        last_response.status.should == 200
        JSON.parse(last_response.body).should include($DB)
      end
    end

    describe "POST" do
      it "creates a database" do
        post "/", :db => "#{$DB}-created"
        last_response.status.should == 201
        get "/"
        JSON.parse(last_response.body).should include($DB+"-created")
      end

      it "errors when database name is omitted" do
        post "/", :foo => "whatever"
        last_response.status.should == 400
      end
    end
  end

  describe "/db" do
    describe "GET" do
      it "returns a list of collection names in the db" do
        get "/#{$DB}"
        last_response.status.should == 200
        JSON.parse(last_response.body).should == []
        
        @db.create_collection(:foo, :size => 0)
        get "/#{$DB}"
        last_response.status.should == 200
        JSON.parse(last_response.body).should include("foo")
      end
    end

    describe "POST" do
      it "creates a collection in the db" do
        post "/#{$DB}", :collection => "faa"
        last_response.status.should == 201
      end
    end
  end

  describe "/db/collection" do
    before(:each) do
      @db.drop_collection("testing")
      @coll = @db.create_collection("testing")
    end

    describe "GET" do
      it "returns a list of records in the collection" do
        get "/#{$DB}/testing"
        last_response.status.should == 200
        JSON.parse(last_response.body).should == []

        id = @coll.save({"foo" => "faa"})
        get "/#{$DB}/testing"
        last_response.status.should == 200
        JSON.parse(last_response.body).should == [{'foo' => 'faa', '_id' => { '$oid' => id.to_s }}]
      end

      describe "using JSON query" do
        before(:each) do
          id1 = @coll.save({"fee" => {"cost" => 1000}, "foo" => "faa"})
          id2 = @coll.save({"fee" => {"cost" => 1000.12}, "faa" => "ccc"})
          id3 = @coll.save({"fee" => {"cost" => 1002.22}, "faa" => "bbb"})
          id4 = @coll.save({"fee" => {"cost" => 1003.22}, "faa" => "aaa", "blah" => ["a", 1, "two"]})
        end

        it "returns a subset of records in the collection using a simple selector" do
          get "/#{$DB}/testing", {:selector => {'foo' => 'faa'}.to_json}
          last_response.status.should == 200
          r = JSON.parse(last_response.body)

          r.length.should == 1
          r.first['foo'].should == 'faa'
        end

        it "returns a subset of records in the collection using a nested selector" do
          get "/#{$DB}/testing", {:selector => {'fee' => {'cost' => 1000.12}, 'faa' => 'ccc'}.to_json}
          last_response.status.should == 200
          r = JSON.parse(last_response.body)

          r.length.should == 1
          r.first['fee'].should == {'cost' => 1000.12}
        end

        it "returns a subset of records in the collection using a nested selector with do notation" do
          get "/#{$DB}/testing", {:selector => {'fee.cost' => 1000.12, 'faa' => 'ccc'}.to_json}
          last_response.status.should == 200
          r = JSON.parse(last_response.body)

          r.length.should == 1
          r.first['fee'].should == {'cost' => 1000.12}
        end

        it "returns a subset of records in the collection using an advanced selector" do
          get "/#{$DB}/testing", {:selector => {'fee.cost' => {'$exists' => true}, 'foo' => {'$not' => {'$exists' => true}}}.to_json}
          last_response.status.should == 200
          r = JSON.parse(last_response.body)

          r.length.should == 3
        end

        it "returns a sorted subset of records in the collection using an advanced selector" do
          get "/#{$DB}/testing", {:selector => {'fee.cost' => {'$exists' => true}, 'foo' => {'$not' => {'$exists' => true}}}.to_json,
                                  :sort => 'faa'}
          last_response.status.should == 200
          r = JSON.parse(last_response.body)
          
          r.length.should == 3
          r.first['faa'].should == 'aaa'
          r.last['faa'].should == 'ccc'
        end

        it "returns a reverse-sorted subset of records in the collection using an advanced selector" do
          get "/#{$DB}/testing", {:selector => {'fee.cost' => {'$exists' => true}, 'foo' => {'$not' => {'$exists' => true}}}.to_json,
                                  :sort => [['fee.cost', 'desc']].to_json}
          last_response.status.should == 200
          r = JSON.parse(last_response.body)
          
          r.length.should == 3
          r.first['faa'].should == 'aaa'
          r.last['faa'].should == 'ccc'
        end
      end
    end

    describe "POST" do
      it "adds an item to the collection" do
        post "/#{$DB}/testing", {"foo" => "faa"}
        last_response.status.should == 201

        foo = @coll.find({'foo' => 'faa'}).to_a
        foo.length.should == 1
        JSON.parse(last_response.body).should == 
          {'foo' => 'faa', '_id' => { '$oid' => foo.first['_id'].to_s }}

        post "/#{$DB}/testing", {"fee" => "foe"}
        last_response.status.should == 201

        @coll.find().to_a.length.should == 2
        fee = @coll.find({'fee' => 'foe'}).to_a
        fee.length.should == 1
        JSON.parse(last_response.body).should == 
          {'fee' => 'foe', '_id' => { '$oid' => fee.first['_id'].to_s }}
      end
    end

    describe "/db/collection/id" do

      describe "GET" do
        it "returns a record from the collection by its id" do
          id = @coll.save({"foo" => "faa"})

          get "/#{$DB}/testing/#{id}"
          last_response.status.should == 200
          JSON.parse(last_response.body).should == {'foo' => 'faa', '_id' => { '$oid' => id.to_s }}
        end

        it "returns a 404 if the item requested from the collection by its id does not exist" do
          id = BSON::ObjectId("000000000000000000000000") # we're assuming an item with this id does not exist

          get "/#{$DB}/testing/#{id}"
          last_response.status.should == 404
        end

        it "JSONifies ISODate values as { $date: '...' }" do
          date1 = Time.now
          date2 = Time.at(Time.now.to_i - 60 * 60 * 10)
          id = @coll.save({"foo" => date1, "bar" => {"bah" => date2}})

          get "/#{$DB}/testing/#{id}"
          doc = JSON.parse(last_response.body)
          doc['foo'].should == { "$date" => date1.getutc.iso8601(1) }
          doc['bar']['bah'].should == { "$date" => date2.getutc.iso8601(1) }
        end
      end

      describe "PUT" do
        it "replaces an item in the collection" do
          id = @coll.save({"foo" => "faa"})

          fff = {"ggg" => "hhh"}

          put "/#{$DB}/testing/#{id}", fff
          last_response.status.should == 200
          JSON.parse(last_response.body).should == 
            fff.merge('_id' => { '$oid' => id.to_s })

          foo = @coll.find_one(id)
          foo.should == fff.merge('_id' => id)
          foo['foo'].should be_nil
          foo['ggg'].should == 'hhh'
        end

        it "stores dates encoded as { $date: '...' } as ISODate" do
          id = @coll.save({"foo" => "faa"})

          date1 = Time.now
          date2 = Time.at(Time.now.to_i - 60 * 60 * 10)

          fff = {"foo" => {"$date" => date1.iso8601(1)}, "bar" => {"bah" => {"$date" => date2.iso8601(1)}}}

          put "/#{$DB}/testing/#{id}", fff
          last_response.status.should == 200

          foo = @coll.find_one(id)
          # NOTE: Mongo stores times as UTC
          foo['foo'].to_i.should == date1.getutc.to_i
          foo['bar']['bah'].to_i.should == date2.getutc.to_i
        end

				# test for bug introduced in c7c944e
				it "can deal with JSON input containing arrays" do
					id = @coll.save({"foo" => "faa"})

					fff = {"foo" => [1,2,3], "bar" => {"bah" => ["a","b","c"]}}

          put "/#{$DB}/testing/#{id}", fff
          last_response.status.should == 200

          foo = @coll.find_one(id)
          foo['foo'].should be_instance_of(Array)
					foo['foo'][0].should == 1
          foo['bar']['bah'].should be_instance_of(Array)
					foo['bar']['bah'][1].should == "b"
				end
      end

      describe "PATCH" do
        it "updates an item in the collection" do
          id = @coll.save({"foo" => "faa"})

          fff = {"ggg" => "hhh"}

          patch "/#{$DB}/testing/#{id}", fff
          last_response.status.should == 200
          JSON.parse(last_response.body).should == 
            fff.merge('_id' => { '$oid' => id.to_s }, 'foo' => 'faa')

          foo = @coll.find_one(id)
          foo['foo'].should == 'faa'
          foo['ggg'].should == 'hhh'
        end
      end

      describe "DELETE" do
        it "deletes an item from the collection" do
          id = @coll.save({"foo" => "faa"})

          delete "/#{$DB}/testing/#{id}"
          last_response.status.should == 200

          foo = @coll.find_one(id)
          foo.should be_nil
        end
      end

    end
  end
end
