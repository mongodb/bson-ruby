# encoding: utf-8
require "json"

module BSON

  # Provides common behaviour for JSON serialization of objects.
  #
  # @since 2.0.0
  module JSON

    # Converting an object to JSON simply gets it's hash representation via
    # as_json, then converts it to a string.
    #
    # @example Convert the object to JSON
    #   object.to_json
    #
    # @note All types must implement as_json.
    #
    # @return [ String ] The object as JSON.
    #
    # @since 2.0.0
    def to_json(*args)
      as_json.to_json(*args)
    end
  end
end
