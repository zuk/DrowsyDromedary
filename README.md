DrowsyDromedary
===============

REST interface for MongoDB written in Ruby


Running
-------

For quick demo or development:

```
gem install bundler
bundle
rackup
```


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

Testing
-------

```
bundle
bundle exec rspec -c -fd -d spec.rb
```