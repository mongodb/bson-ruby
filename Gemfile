source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'rake'
  gem 'rake-compiler'
  gem 'yard'

  gem 'rspec', '~> 3'
  gem 'json'
  gem 'activesupport'
  gem 'ruby-prof', platforms: :mri

  gem 'byebug', platforms: :mri
  # https://github.com/jruby/jruby/wiki/UsingTheJRubyDebugger
  gem 'ruby-debug', platforms: :jruby
end

group :test do
  gem 'fuubar'
  gem 'rfc'
end
