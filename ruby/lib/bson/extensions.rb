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
  extend  BSON::Extensions::Array::ClassMethods
  include BSON::Extensions::Array
end

class FalseClass
  include BSON::Extensions::FalseClass
end

class Float
  extend  BSON::Extensions::Float::ClassMethods
  include BSON::Extensions::Float
end

class Hash
  include BSON::Extensions::Hash
end

class Integer
  include BSON::Extensions::Integer
end

class NilClass
  extend  BSON::Extensions::NilClass::ClassMethods
  include BSON::Extensions::NilClass
end

class Regexp
  extend  BSON::Extensions::Regexp::ClassMethods
  include BSON::Extensions::Regexp
end

class String
  extend  BSON::Extensions::String::ClassMethods
  include BSON::Extensions::String
end

class Symbol
  extend  BSON::Extensions::Symbol::ClassMethods
  include BSON::Extensions::Symbol
end

class Time
  extend  BSON::Extensions::Time::ClassMethods
  include BSON::Extensions::Time
end

class TrueClass
  include BSON::Extensions::TrueClass
end
