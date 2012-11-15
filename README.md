DrowsyDromedary
===============

DrowsyDromedary is the Ruby answer to [Sleepy.Mongoose](https://github.com/kchodorow/sleepy.mongoose), 
a REST interface for [MongoDB](http://www.mongodb.org/).


Quickstart
----------

You'll need a working Ruby environment (tested on 1.9) with [Bundler](http://gembundler.com/) installed.

`cd` into the directory where you clonedd the DrowsyDromedary source and run:

```
bundle
rackup
```

Drowsy should now be running at [http://localhost:9292](http://localhost:9292), talking to your `mongod` running on localhost.
Currently Drowsy cannot talk to a `mongod` instance on another machine, but this will likely change in the future.

Production Deployment
---------------------

DrowsyDromedary should work with any [Rack](http://rack.github.com/) container.
We use [Phusion Passenger](http://www.modrails.com/documentation.html) with Apache.

To deploy with Passenger:

1. Clone Drowsy and create a virtual host for it.
   Point the `DocumentRoot` to Drowsy's `public` subdirectory.
2. [Install Passenger for Apache](http://www.modrails.com/documentation/Users%20guide%20Apache.html#_installing_upgrading_and_uninstalling_phusion_passenger)
4. cd into the Drowsy install dirctory and run:

```
gem install bundler
bundle --without development
```

DrowsyDromedary should now be up and running.

Running RSpec Tests
-------------------

```
bundle
bundle exec rspec -c -fd spec.rb
```

Security
--------

By default DrowsyDromedary is wide open. This means that **your entire MongoDB system will be exposed**. 

If you are publicly exposing your Drowsy, it is extremely important to lock down access to the service.
This can be done with additional configuration to the Rack container running your app. For example, if you are
deploying using Apache (via Passenger), you could limit access to specific hosts and/or implement HTTP
authentication using [mod_auth](http://httpd.apache.org/docs/2.0/howto/auth.html).

Another option is to add Rack middleware for authorization and authentication. This would be done by modifying
Drowsy's [`config.ru`](https://github.com/zuk/DrowsyDromedary/blob/master/config.ru) file. [Warden](https://github.com/hassox/warden/wiki) is one such middleware option.

#### CORS (Cross-domain Browser Requests)

The default DrowsyDromedary configuration has an open [CORS](http://en.wikipedia.org/wiki/Cross-origin_resource_sharing)
configuration. Cross-domain browser requests to Drowsy are allowed from all domains for all HTTP methods.

CORS access can be restricted by modifying the `Rack::Cors` section of Drowsy's
[`config.ru`](https://github.com/zuk/DrowsyDromedary/blob/master/config.ru) file.

Note that due to some questionable decisions in the CORS spec, CORS requests that result in an error 
(`404`, `500`, etc.) will always have a blank body (i.e. no detailed error message). If you want better error
handling, consider putting DrowsyDromedary behind a same-origin reverse proxy.


********************************************

Usage
-----

Usage examples with browser-side JavaScript frameworks:

* [jQuery Example](https://gist.github.com/2876909)
* [Backbone.js Example](https://gist.github.com/2877040)

API
===

Replace `db` with your database name and `collection` with your collection name.
All parameters must be given as valid JSON strings, and all responses (including errors) are returned in JSON format.


`GET /`
-------
**List databases**

###### Response

`Status: 200`
```json
[
  "groceries",
  "fridge",
  "pantry"
]
```

`POST /`
-------
**Create a database**

###### Parameters

`db`
  * The name of the database to create.


`GET /db`
------------------------------
**List collections in a database**

###### Response

```json
[
  "fruits",
  "vegetables",
  "snacks"
]
```

`POST /db`
----------
**Create a collection in a database**

###### Parameters

`collection`
  * The name of the collection to create.


`GET /db/collection`
--------------------
**List items in a collection**

###### Parameters

`selector`
  * A [Mongo query expression](http://www.mongodb.org/display/DOCS/Querying) specifying which items to return.
  * Examples:
    * `{"fruit":"apple","colour":"green"}` (all items where 'fruit' is 'apple' and 'colour' is 'green')
    * `{"fruit":{"$exists":true}}` (all items that have a 'fruit' property)
    * Example Request:
      * `GET` http://drowsy.example.com/fridge/crisper?selector={"fruit":{"$exists":true}}
          * Note that the `selector` value should be URL encoded; however most browsers will do this for you if you 
            enter the un-encoded query in the URL bar.
         

`sort`
  * An array of property-order pairs to sort on.
  * Examples:
    * `["fruit","DESC"]` (sort by the 'fruit' property, in descending order)
    * `["fruit","ASC"]` (sort by the 'fruit' property, in ascending order)
    * `[["fruit","ASC"],["colour","DESC"]]` (sort by the 'fruit' property first in ascending order and then by the 'colour' property in descending order)
    * Example Request:
      * `GET` http://drowsy.example.com/fridge/crisper?sort=[["fruit","ASC"],["colour","DESC"]]
          * Note that the `sort` value should be URL encoded; however most browsers will do this for you if you 
            enter the un-encoded query in the URL bar.

###### Response

`Status: 200`
```json
[
  {
    "_id": { "$oid": "4deeb1d9349c85523b000001" },
    "fruit": "orange",
    "colour": "orange"
  },
  {
    "_id": { "$oid": "4deeb1d9349c85523b000002" },
    "fruit": "kiwi",
    "colour": "brown",
    "size": "small"
  },
  {
    "_id": { "$oid": "4deeb1d9349c85523b000003" },
    "fruit": "banana",
    "colour": "yellow",
    "organic": true
  }
]
```

`POST /db/collection`
---------------------
**Add an item to a collection**

The request data should contain a full representation of the item to create. This can be sent either as regular, url-encoded form data 
(i.e. `Content-Type: application/x-www-form-urlencoded`), or as a JSON-encoded string (i.e. `Content-Type: application/json`).

The server will respond with a full representation of the newly created object, with a server-generated `_id` if none was provided
in the request data.

###### Request

`POST /groceries/cart`
```json
{
  "fruit": "apple",
  "colour": "red",
  "variety": "Macintosh"
}
```

###### Response

`Status: 201`
```json
{
  "_id": { "$oid": "4deeb1d9349c85523b000004" },
  "fruit": "apple",
  "colour": "red",
  "variety": "Macintosh"
}
```


`PUT /db/collection/id`
-----------------------
**Replace an item in a collection**

The request data should contain a full representation of the item to replace. This can be sent either as regular, url-encoded form data 
(i.e. `Content-Type: application/x-www-form-urlencoded`), or as a JSON-encoded string (i.e. `Content-Type: application/json`).

If the item with the given id does not yet exist, it will be automatically created. However this behaviour is subject to change
in a future version (an additional parameter may be required to enable this "upsert" behaviour).

###### Request

`PUT /groceries/cart/4deeb1d9349c85523b000004`
```json
{
  "fruit": "apple",
  "colour": "green",
  "variety": "Golen Delicious"
}
```

###### Response

`Status: 200`
```json
{
  "_id": { "$oid": "4deeb1d9349c85523b000004" },
  "fruit": "apple",
  "colour": "green",
  "variety": "Golen Delicious"
}
```


`PATCH /db/collection/id`
-------------------------
**Partially replace an item in a collection**

Unlike a PUT, a PATCH request will only replace the given properties (instead of replacing the entire item).

The request data should contain a full representation of the item to replace. This can be sent either as regular, url-encoded form data 
(i.e. `Content-Type: application/x-www-form-urlencoded`), or as a JSON-encoded string (i.e. `Content-Type: application/json`).

If the item with the given id does not yet exist, the server will respond with `404` (`Not Found`).

###### Request

`PATCH /groceries/cart/4deeb1d9349c85523b000004`
```json
{
  "colour": "orange"
}
```

###### Response

`Status: 200`
```json
{
  "_id": { "$oid": "4deeb1d9349c85523b000004" },
  "fruit": "apple",
  "colour": "orange",
  "variety": "Golen Delicious"
}
```


`DELETE /db/collection/id`
--------------------------
**Delete an item from a collection**

Note that the request will succeed regardless of whether an item with the given id exists.

###### Request

`DELETE /groceries/cart/4deeb1d9349c85523b000004`

###### Response

`Status: 200`
```json
{}
```