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
bundle exec rspec -c -fd -d spec.rb
```