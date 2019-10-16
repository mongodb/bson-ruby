lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bson/version'

Gem::Specification.new do |s|
  s.name              = 'bson'
  s.rubyforge_project = 'bson'
  s.version           = BSON::VERSION
  s.authors           = ['Tyler Brock', 'Durran Jordan', 'Brandon Black', 'Emily Stolfo', 'Gary Murakami']
  s.email             = ['mongodb-dev@googlegroups.com']
  s.homepage          = 'http://bsonspec.org'
  s.summary           = 'Ruby Implementation of the BSON specification'
  s.description       = 'A full featured BSON specification implementation, in Ruby'
  s.license           = 'Apache-2.0'

  s.metadata = {
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
