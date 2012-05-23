DrowsyDromedary
===============

REST interface for MongoDB written in Ruby


Running
-------

In production:

```
gem install bundler
bundle --without development
rackup
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