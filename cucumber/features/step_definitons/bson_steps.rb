Given /^a document containing a (\S+) with value (\S+)$/ do |type, value|
  if type == "float"
    value = value.to_f
  elsif type == "string"
    value = value
  elsif type == "binary"
    value = BSON::Binary.new(value)
  elsif type == "true"
    value = true
  elsif type == "false"
    value = false
  elsif type == "datetime"
    value = Time.at(value.to_i)
  elsif type == "null"
    value = nil
  elsif type == "regex"
    value = Regexp.new value
  elsif type == "code"
    value = BSON::Code.new(value)
  elsif type == "symbol"
    value = value.to_sym
  elsif type == "code_ws"
    value = BSON::Code.new(value, {})
  elsif type == "int32"
    value = value.to_i
  elsif type == "int64"
    value = value.to_i
  elsif type == "min_key"
    value = BSON::MinKey.new
  elsif type == "max_key"
    value = BSON::MaxKey.new
  end
  @doc = {:k => value}
end

When /^I serialize the document$/ do
  @bson = BSON.serialize(@doc)
end

Then /^the result should be ([0-9a-fA-F]+)$/ do |hex_bytes|
  @bson.unpack("H*")[0].should eq(hex_bytes)
end
