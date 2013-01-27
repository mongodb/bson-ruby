module Mongo
  module Protocol
    class Insert
      include Message

      OP_CODE = 2002

      attr_reader :database
      attr_reader :collection

      def initialize(database, collection, documents, flags=0)
        fields << flags.to_bson
        fields << "#{database}.#{collection}".to_bson_cstring
        fields << documents.each { |doc| BSON::serialize(doc) }
      end
    end
  end
end
