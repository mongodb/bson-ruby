lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "bson/version"

Gem::Specification.new do |s|
  s.name        = "bson"
  s.version     = BSON::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Tyler Brock", "Durran Jordan"]
  s.email       = ["mongodb-dev@googlegroups.com"]
  s.homepage    = "http://bsonspec.org"
  s.summary     = "Ruby Implementation of the BSON specification"
  s.description = "A full featured BSON specification implementation, in Ruby"
  s.license     = "Apache License Version 2.0"

  unless File.exists?("gem-private_key.pem")
    warn "Warning! No private key present, creating unsigned gem."
  else
    s.signing_key = "gem-private_key.pem"
    s.cert_chain  = ["gem-public_cert.pem"]
  end

  s.required_ruby_version     = ">= 1.8.7"
  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "bson"
  s.extensions   = "ext/bson/extconf.rb"
  s.files        = Dir.glob("lib/**/*") + %w(CHANGELOG.md LICENSE.md README.md Rakefile)
  s.require_path = "lib"
end
