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

  # JRuby 9.3 reports RUBY_VERSION as 2.6, and the latest versions of Rubocop
  # wants 2.7 or higher. It enough to use rubocop only on MRI, so we can skip
  # it on JRuby.
  unless RUBY_PLATFORM =~ /java/
    gem 'rubocop', '~> 1.75.5'
    gem 'rubocop-performance', '~> 1.25.0'
    gem 'rubocop-rake', '~> 0.7.1'
    gem 'rubocop-rspec', '~> 3.6.0'
  end
end

group :test do
  gem 'fuubar'
  gem 'rfc'
  gem "rspec_junit_formatter"
end
