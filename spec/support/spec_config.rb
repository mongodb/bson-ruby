require 'singleton'

class SpecConfig
  include Singleton

  COMPACTION_CHANCE = 0.001

  def active_support?
    %w(1 true yes).include?(ENV['WITH_ACTIVE_SUPPORT']) ||
      ENV['WITH_ACTIVE_SUPPORT'] =~ /[0-9]/ && ENV['WITH_ACTIVE_SUPPORT'] != '0'
  end

  def compact?
    %w(1 true yes).include?(ENV['COMPACT'])
  end
end
