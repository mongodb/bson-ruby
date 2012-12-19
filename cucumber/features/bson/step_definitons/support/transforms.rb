Transform /^double value (-?\d+\.?\d+)$/ do |double|
  double.to_f
end

Transform /^string value (\S+)$/ do |string|
  string
end

Transform /^binary value (\S+)$/ do |binary|
  BSON::Binary.new(binary)
end

Transform /^boolean value (\S+)$/ do |boolean|
  boolean == 'true'
end

Transform /^datetime value (\S+)$/ do |datetime|
  Time.at(datetime.to_i)
end

Transform /^null value (\S+)$/ do |null|
  nil
end

Transform /^symbol value (\S+)$/ do |symbol|
  symbol.to_sym
end

Transform /^regex value (\S+)$/ do |regex|
  /#{regex}/
end

Transform /^int32 value (-?\d+)$/ do |int32|
  int32.to_i
end

Transform /^int64 value (-?\d+)$/ do |int64|
  int64.to_i
end

Transform /^min_key value (\S+)$/ do |min_key|
  BSON::MinKey
end

Transform /^max_key value (\S+)$/ do |max_key|
  BSON::MaxKey
end