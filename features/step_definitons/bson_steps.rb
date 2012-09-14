Given /^a key value (.*)$/ do |key|
  @key = key
end

Given /^a double value (-?\d+.\d+)$/ do |double|
  @value = double.to_f
end

When /^i serialize the key and value$/ do
  @result = "\x01" + @key + "\x00" + [@value].pack("d")
end

Then /^the result should be (.*)$/ do |hex_bytes|
  @result.unpack("H*").first.should == hex_bytes
end

