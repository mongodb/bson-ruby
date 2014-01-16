source 'https://rubygems.org'

gem 'json', :platforms => [ :ruby_18, :jruby ]
gem 'rake'

group :development, :test do
  gem 'rspec'
  gem 'rake-compiler'

  if ENV['CI']
    gem 'coveralls', :require => false
    gem 'mime-types', '1.25' # v2.0+ does not supporty ruby 1.8
    gem "rubysl-singleton", "~> 2.0", :platforms => :rbx
  else
    gem 'ruby-prof', :platforms => :mri
    gem 'pry'
    gem 'guard-rspec', :platforms => [ :ruby_19, :ruby_20, :ruby_21 ]
    gem 'rb-inotify', :require => false # Linux
    gem 'rb-fsevent', :require => false # OS X
    gem 'rb-fchange', :require => false # Windows
    gem 'terminal-notifier-guard'
  end
end
