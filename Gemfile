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
    gem 'activesupport', '<7'
  end
  gem 'ruby-prof', platforms: :mri

  gem 'byebug', platforms: :mri
  # https://github.com/jruby/jruby/wiki/UsingTheJRubyDebugger
  gem 'ruby-debug', platforms: :jruby
end

group :test do
  gem 'fuubar'
  gem 'rfc'
end
