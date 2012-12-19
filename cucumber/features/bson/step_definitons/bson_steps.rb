Given /^a document containing a ((?:\S+) value (?:.+))$/ do |value|
  @doc = {:k => value}
end

Given /^an IO stream with containing ([0-9a-fA-F]+)$/ do |hex_bytes|
  @io = StringIO.new([hex_bytes].pack('H*'))
end

When /^I serialize the document$/ do
  @bson = BSON::serialize(@doc)
end

When /^I deserialize the IO stream$/ do
  @object = BSON::deserialize(@io)
end

Then /^the result should be ([0-9a-fA-F]+)$/ do |hex_bytes|
  @bson.unpack("H*")[0].should eq(hex_bytes)
end

Then /^the result should be a (\S+) with value (\S+)$/ do |bson_type, value|
  binary_bson_type = [bson_type].pack('H*')
  @object['k'].class eq(BSON::Types::MAP[binary_bson_type].class)
  @object['k'].should eq(BSON::Types::MAP[binary_bson_type].new(value))
end