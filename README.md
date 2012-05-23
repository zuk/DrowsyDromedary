DrowsyDromedary
===============

REST interface for MongoDB written in Ruby


Running
-------

In production:

1. Clone to Apache-servable directory
2. Install passenger for Apache
3. Create vhost pointing to the directory where you cloned
4. cd into cloned dirctory
5. Run:

```
gem install bundler
bundle --without development
```

For development:

```
gem install bundler
bundle
rackup
```

Testing
-------

```
bundle
bundle exec rspec -c -fd -d spec.rb
```