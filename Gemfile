source 'https://rubygems.org'

gemspec
if RUBY_VERSION >= '2.3.0'
  gem 'json'
else
  gem 'json', '~> 1.8'
end
gem 'rake'

group :development, :test do
  gem 'rspec', '~> 3.2'
  gem 'rake-compiler'
  gem 'ruby-prof', :platforms => :mri
  
  if ENV['CI']
    gem 'mime-types', '1.25' # v2.0+ does not support ruby 1.8
  else
    gem 'pry'
  end
end
