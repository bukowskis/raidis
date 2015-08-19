require 'redis/namespace'
require 'timeout'

require 'raidis/availability'
require 'raidis/configuration'
require 'raidis/configurable'
require 'raidis/redis_wrapper'

module Raidis

  ConnectionError = Class.new RuntimeError

  extend self
  extend Availability

  # Public: The singleton Redis connection object.
  #
  # Returns a RedisWrapper instance.
  #
  def redis(identifier = :default)
    return redises[identifier] if redises[identifier]
    redises[identifier] = redis!
    connected? identifier
    redises[identifier]
  end

  # Public: Updates the #available? flag by actually testing the Redis connection.
  #
  # Returns true or false.
  #
  def connected?(identifier = :default)
    return unavailable!(identifier) unless redises[identifier]
    @redises[identifier].setex(:raidis, 1, :rocks) && available!

  rescue Raidis::ConnectionError
    unavailable! identifier
  end

  # Public: Evokes a fresh lookup of the Redis server endpoint.
  #
  def reconnect!(identifier = :default)
    @redises = nil
    redis identifier
  end

  # Public: Creates a brand-new failsafe-wrapped connection to Redis.
  # This is ONLY useful if you need to maintain your own ConnectionPool.
  # See https://github.com/mperham/sidekiq/issues/794
  #
  def redis!
    RedisWrapper.new
  end

  private

  def redises
    @redises ||= {}
  end

end
