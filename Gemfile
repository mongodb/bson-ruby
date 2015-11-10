source 'https://rubygems.org'

gem 'json', :platforms => [ :jruby ]
gem 'rake'

group :development, :test do
  gem 'rspec', '~> 3.2'
  gem 'rake-compiler'
  gem 'ruby-prof', :platforms => :mri

  if !ENV['CI']
    gem 'pry'
  end
end
