Given /^a document containing a ((?:\S+) value (?:.+))$/ do |value|
  @doc = {:k => value}
end

Given /^an IO stream containing ([0-9a-fA-F]+)$/ do |hex_bytes|
  @io = StringIO.new([hex_bytes].pack('H*'))
end

When /^I serialize the document$/ do
  @bson = BSON::serialize(@doc)
end

When /^I deserialize the stream$/ do
  @document = BSON::deserialize(@io)
end

Then /^the result should be ([0-9a-fA-F]+)$/ do |hex_bytes|
  @bson.last.unpack('H*')[0].should eq(hex_bytes)
end

Then /^the result should be the ((?:\S+) value (?:\S+))$/ do |value|
  @document['k'].should eq(value)
end


Given /^a (\S+ value(?: .*)?)$/ do |value|
  @value = value
end

When /^I serialize the value$/ do
  @bson = @value.to_bson
end

Then /^the BSON element should have the (BSON type \S+)$/ do |type|
  @bson.first.should == type
end

Given /^a (?:\S+) with the following items:$/ do |obj|
  @value = obj
end

Then /^the result should be the bson document:$/ do |doc|
  @bson.last.should == doc
end

