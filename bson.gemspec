lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bson/version'

Gem::Specification.new do |s|
  s.name              = 'bson'
  s.rubyforge_project = 'bson'
  s.version           = BSON::VERSION
  s.platform          = Gem::Platform::RUBY

  s.authors           = ['Tyler Brock', 'Durran Jordan', 'Brandon Black', 'Emily Stolfo', 'Gary Murakami']
  s.email             = ['mongodb-dev@googlegroups.com']
  s.homepage          = 'http://bsonspec.org'
  s.summary           = 'Ruby Implementation of the BSON specification'
  s.description       = 'A full featured BSON specification implementation, in Ruby'
  s.license           = 'Apache License Version 2.0'

  if File.exists?('gem-private_key.pem')
    s.signing_key = 'gem-private_key.pem'
    s.cert_chain  = ['gem-public_cert.pem']
  else
    warn "[#{s.name}] Warning: No private key present, creating unsigned gem."
  end

  s.files      = %w(CONTRIBUTING.md CHANGELOG.md LICENSE.md README.md Rakefile)
  s.files      += Dir.glob('lib/**/*')
  s.extensions = ['ext/bson/extconf.rb'] unless RUBY_PLATFORM =~ /java/

  s.require_path              = 'lib'
  s.required_ruby_version     = '>= 1.8.7'
  s.required_rubygems_version = '>= 1.3.6'
  s.has_rdoc                  = 'yard'
end
