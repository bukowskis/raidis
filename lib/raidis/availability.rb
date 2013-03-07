module Raidis
  extend self

  def available?
    !!@available
  end

  private

  def self.available!
    @available = true
  end

  def self.unavailable!
    @available = false
  end

end
