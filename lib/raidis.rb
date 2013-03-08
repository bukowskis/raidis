require 'redis/namespace'
require 'timeout'

require 'raidis/availability'
require 'raidis/configuration'
require 'raidis/redis_wrapper'

module Raidis

  ConnectionError = Class.new(RuntimeError)

  extend self
  extend Availability

  def redis
    return @redis if @redis
    @redis = RedisWrapper.new redis!
    connected?
    @redis
  end

  def connected?
    return unavailable! unless @redis
    @redis.setex(:raidis, 1, :rocks) && available!
  rescue Raidis::ConnectionError
    unavailable!
  end

  def reconnect!
    @redis = nil
    redis
  end

  private

  def redis!
    return unless master = config.master
    raw_redis = Redis.new db: config.redis_db, host: master.endpoint, port: master.port, timeout: config.redis_timeout
    Redis::Namespace.new config.redis_namespace, redis: raw_redis
  end
end
