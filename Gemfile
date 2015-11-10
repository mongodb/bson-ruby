source 'https://rubygems.org'

gem 'json', :platforms => [ :jruby ]
gem 'rake'

group :development, :test do
  gem 'rspec', '~> 3.2'
  gem 'rake-compiler'
  gem 'ruby-prof', :platforms => :mri

  if ENV['CI']
    platforms :ruby_20, :ruby_21, :jruby do
      gem 'coveralls', :require => false
    end
    gem 'mime-types', '1.25' # v2.0+ does not supporty ruby 1.8
  else
    gem 'pry'
  end
end
