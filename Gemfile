source :rubygems

gem 'grape', :git => 'git://github.com/intridea/grape.git', :ref => "346fb94"
gem 'json'
gem 'mongo'
gem 'bson'
gem 'bson_ext'
gem 'rack-cors', :require => 'rack/cors'
#added thin to get around silly WEbrick errors
gem 'thin'
#added shotgun for simpler Rack starts
gem 'shotgun'
group :development do
  gem 'rspec'
  gem 'rack-test', :git => "https://github.com/brynary/rack-test.git", :ref => "cab8eb929b" # adds PATCH http method support
  gem 'autotest'
  gem 'autotest-inotify'
end
