require 'bson/extensions/array'
require 'bson/extensions/hash'
require 'bson/extensions/integer'
require 'bson/extensions/nil_class'
require 'bson/extensions/string'
require 'bson/extensions/regexp'
require 'bson/extensions/float'
require 'bson/extensions/symbol'
require 'bson/extensions/false_class'
require 'bson/extensions/true_class'
require 'bson/extensions/time'

class Array
  include BSON::Extensions::Array
end

class FalseClass
  include BSON::Extensions::FalseClass
end

class Float
  include BSON::Extensions::Float
end

class Hash
  include BSON::Extensions::Hash
end

class Integer
  include BSON::Extensions::Integer
end

class NilClass
  include BSON::Extensions::NilClass
end

class String
  include BSON::Extensions::String
end

class TrueClass
  include BSON::Extensions::TrueClass
end

class Time
  include BSON::Extensions::Time
end

class NilClass
  include BSON::Extensions::NilClass
end

class Regexp
  include BSON::Extensions::Regexp
end

class Symbol
  include BSON::Extensions::Symbol
end

class Integer
  include BSON::Extensions::Integer
end

