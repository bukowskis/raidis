module Raidis
  extend self

  def available?
    !!@available
  end

  private

  def self.available!
    @available = true
    nil
  end

  def self.unavailable!
    @available = false
    nil
  end

end
