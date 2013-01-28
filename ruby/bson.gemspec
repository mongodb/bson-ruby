Gem::Specification.new do |s|
  s.name              = 'bson'
  s.authors           = 'Tyler Brock'
  s.email             = 'mongodb-dev@googlegroups.com'
  s.homepage          = 'http://www.bsonspec.org'
  s.summary           = 'Ruby implementation of BSON'
  s.description       = 'A Ruby BSON implementation'
  s.rubyforge_project = 'bson'

  s.version           = File.read(File.join(File.dirname(__FILE__), 'VERSION'))
  s.platform          = Gem::Platform::RUBY

  s.files             = ['lib/bson.rb']
  s.require_paths     = ['lib']
end