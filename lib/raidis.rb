require 'redis/namespace'
require 'timeout'

require 'raidis/availability'
require 'raidis/configuration'
require 'raidis/redis_wrapper'

module Raidis

  ConnectionError = Class.new(RuntimeError)

  extend self
  extend Availability

  # Public: The singleton Redis connection object.
  #
  # Returns a RedisWrapper instance.
  #
  def redis
    return @redis if @redis
    @redis = redis!
    connected?
    @redis
  end

  # Public: Updates the #available? flag by actually testing the Redis connection.
  #
  # Returns true or false.
  #
  def connected?
    return unavailable! unless @redis
    @redis.setex(:raidis, 1, :rocks) && available!
  rescue Raidis::ConnectionError
    unavailable!
  end

  # Public: Evokes a fresh lookup of the Redis server endpoint.
  #
  def reconnect!
    @redis = nil
    redis
  end

  # Public: Creates a brand-new failsafe-wrapped connection to Redis.
  # This is ONLY useful if you need to maintain your own ConnectionPool.
  # See https://github.com/mperham/sidekiq/issues/794
  #
  def redis!
    RedisWrapper.new
  end
end
