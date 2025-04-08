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

  # Ruby 2.5 wants an older version of rubocop. Rather than try to
  # please everybody, we'll just not install rubocop for Ruby 2.5.
  if RUBY_VERSION > "2.5.99"
    gem 'rubocop', '~> 1.45.1'
    gem 'rubocop-performance', '~> 1.16.0'
    gem 'rubocop-rake', '~> 0.6.0'
    gem 'rubocop-rspec', '~> 2.18.1'
  end
end

group :test do
  gem 'fuubar'
  gem 'rfc'
end
