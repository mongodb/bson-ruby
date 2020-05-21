lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bson/version'

Gem::Specification.new do |s|
  s.name              = 'bson'
  s.version           = BSON::VERSION
  s.authors           = ['Tyler Brock', 'Durran Jordan', 'Brandon Black', 'Emily Stolfo', 'Gary Murakami']
  s.homepage          = 'https://docs.mongodb.com/ruby-driver/current/tutorials/bson-v4/'
  s.summary           = 'Ruby implementation of the BSON specification'
  s.description       = 'A fully featured BSON specification implementation in Ruby'
  s.license           = 'Apache-2.0'

  s.metadata = {
    'bug_tracker_uri' => 'https://jira.mongodb.org/projects/RUBY',
    'changelog_uri' => 'https://github.com/mongodb/bson-ruby/releases',
    'documentation_uri' => 'https://docs.mongodb.com/ruby-driver/current/tutorials/bson-v4/',
    'homepage_uri' => 'https://docs.mongodb.com/ruby-driver/current/tutorials/bson-v4/',
    'source_code_uri' => 'https://github.com/mongodb/bson-ruby'
  }

  if File.exists?('gem-private_key.pem')
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

  s.test_files = Dir.glob('spec/**/*')

  s.require_path              = 'lib'
  s.required_ruby_version     = '>= 2.3'
  s.required_rubygems_version = '>= 1.3.6'
end
