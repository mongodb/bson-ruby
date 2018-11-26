require 'singleton'

class SpecConfig
  include Singleton

  def active_support?
    %w(1 true yes).include?(ENV['WITH_ACTIVE_SUPPORT'])
  end
end
