# frozen_string_literal: true
# rubocop:todo all

source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'rake'
  gem 'rake-compiler'
  gem 'yard'

  gem 'rspec', '~> 3'
  gem 'json'
  if ENV['WITH_ACTIVE_SUPPORT'] =~ /[0-9]/ && ENV['WITH_ACTIVE_SUPPORT'] != '0'
    gem 'activesupport', ENV['WITH_ACTIVE_SUPPORT']
  else
    gem 'activesupport', '<8.1'
  end
  gem 'concurrent-ruby', '1.3.4'
  gem 'ruby-prof', platforms: :mri

  gem 'byebug', platforms: :mri
  # https://github.com/jruby/jruby/wiki/UsingTheJRubyDebugger
  gem 'ruby-debug', platforms: :jruby

  gem 'rubocop', '~> 1.75.5'
  gem 'rubocop-performance', '~> 1.25.0'
  gem 'rubocop-rake', '~> 0.7.1'
  gem 'rubocop-rspec', '~> 3.6.0'
end

group :test do
  gem 'fuubar'
  gem 'rfc'
end
