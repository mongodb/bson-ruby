# frozen_string_literal: true
# rubocop:todo all

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bson/version'

Gem::Specification.new do |s|
  s.name              = 'bson'
  s.version           = BSON::VERSION
  s.authors           = ["The MongoDB Ruby Team"]
  s.email             = "dbx-ruby@mongodb.com"
  s.homepage          = 'https://www.mongodb.com/docs/ruby-driver/current/tutorials/bson-v4/'
  s.summary           = 'Ruby implementation of the BSON specification'
  s.description       = 'A fully featured BSON specification implementation in Ruby'
  s.license           = 'Apache-2.0'

  s.metadata = {
    'bug_tracker_uri' => 'https://jira.mongodb.org/projects/RUBY',
    'changelog_uri' => 'https://github.com/mongodb/bson-ruby/releases',
    'documentation_uri' => 'https://www.mongodb.com/docs/ruby-driver/current/tutorials/bson-v4/',
    'homepage_uri' => 'https://www.mongodb.com/docs/ruby-driver/current/tutorials/bson-v4/',
    'source_code_uri' => 'https://github.com/mongodb/bson-ruby'
  }

  if File.exist?('gem-private_key.pem')
    s.signing_key = 'gem-private_key.pem'
    s.cert_chain  = ['gem-public_cert.pem']
  else
    warn "[#{s.name}] Warning: No private key present, creating unsigned gem."
  end

  s.files      = %w(CONTRIBUTING.md CHANGELOG.md LICENSE NOTICE README.md Rakefile)
  s.files      += Dir.glob('lib/**/*')

  unless RUBY_PLATFORM =~ /java/
    s.platform   = Gem::Platform::RUBY
    s.files      += Dir.glob('ext/**/*.{c,h,rb}')
    s.extensions = ['ext/bson/extconf.rb']
  else
    s.platform   = 'java'
  end

  if RUBY_VERSION > '3.2.99'
    s.add_dependency 'base64'
    s.add_dependency 'bigdecimal'
  end

  s.test_files = Dir.glob('spec/**/*')

  s.require_path              = 'lib'
  s.required_ruby_version     = '>= 2.5'
  s.required_rubygems_version = '>= 1.3.6'
end
