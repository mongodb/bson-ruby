Gem::Specification.new do |s|
  s.name              = 'mongo'
  s.authors           = 'Tyler Brock'
  s.email             = 'mongodb-dev@googlegroups.com'
  s.homepage          = 'http://www.mongodb.org'
  s.summary           = 'Ruby driver for MongoDB'
  s.description       = 'A Ruby BSON implementation for MongoDB'
  s.rubyforge_project = 'mongo'

  s.version           = File.read(File.join(File.dirname(__FILE__), 'VERSION'))
  s.platform          = Gem::Platform::RUBY

  s.files             = ['lib/mongo.rb']
  s.executables       = ['mongo_console']
  s.require_paths     = ['lib']

  s.add_dependency('bson', "~> #{s.version}")
end