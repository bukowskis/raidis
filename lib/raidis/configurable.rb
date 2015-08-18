module Raidis
  extend self

  def config(identifier = :default)
    @configs ||= {}
    @configs[identifier] ||= Configuration.new
  end

  def configure(identifier = :default)
    yield config(identifier)
  end

  def reset_configuration!
    @configs = nil
  end
end
