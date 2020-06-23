require 'singleton'

class SpecConfig
  include Singleton

  COMPACTION_CHANCE = 0.001

  def active_support?
    %w(1 true yes).include?(ENV['WITH_ACTIVE_SUPPORT'])
  end

  def compact?
    %w(1 true yes).include?(ENV['COMPACT'])
  end
end

RSpec.configure do |config|
  if SpecConfig.instance.compact?
    config.after do
      if rand < SpecConfig::COMPACTION_CHANCE
        GC.compact
      end
    end
  end
end
