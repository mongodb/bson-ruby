Transform /^double value(?: (-?\d+\.?\d+))?$/ do |double|
  double.to_f
end

Transform /^string value(?: (\S+))?$/ do |string|
  string.to_s
end

Transform /^document value(?: (\S+))?$/ do |document|
  Hash.new
end

Transform /^array value(?: (\[.*\]))?$/ do |array|
  Array.new
end

Transform /^binary value(?: (\S+))?$/ do |binary|
  BSON::Binary.new(binary.to_s)
end

Transform /^undefined value(?: (\S+))?$/ do |undefined|
  BSON::Undefined
end

Transform /^object_id value(?: (\S+))?$/ do |obj_id|
  BSON::ObjectId.from_string(obj_id)
end

Transform /^boolean value(?: (\S+))?$/ do |boolean|
  boolean == 'true'
end

Transform /^datetime value(?: (\S+))?$/ do |datetime|
  Time.at(datetime.to_i)
end

Transform /^null value(?: (\S+))?$/ do |null|
  nil
end

Transform /^symbol value(?: (\S+))?$/ do |symbol|
  symbol.to_sym
end

Transform /^code_w_scope value(?: (\S+))?$/ do |code|
  BSON::Code.new(code.to_s, {:a => 1})
end

Transform /^regex value(?: (\S+))?$/ do |regex|
  /#{regex}/
end

Transform /^db_pointer value(?: (\S+))?$/ do |db_pointer|
  BSON::DBPointer.new("a.b", BSON::ObjectId.new("50d3409d82cb8a4fc7000001"))
end

Transform /^code value(?: (\S+))?$/ do |code|
  BSON::Code.new(code.to_s)
end

Transform /^symbol value(?: (\S+))?$/ do |symbol|
  symbol.to_s.intern
end

Transform /^int32 value(?: (-?\d+))?$/ do |int32|
  int32.to_i
end

Transform /^timestamp value(?: (-?\d+))?$/ do |ts|
  BSON::Timestamp.new(Time.now, 0)
end

Transform /^int64 value(?: (-?\d+))?$/ do |int64|
 int64 ? int64.to_i : 2**62
end

Transform /^min_key value(?: (\S+))?$/ do |min_key|
  BSON::MinKey
end

Transform /^max_key value(?: (\S+))?$/ do |max_key|
  BSON::MaxKey
end