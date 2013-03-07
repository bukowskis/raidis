require 'raidis/configuration'
require 'raidis/availability'

module Raidis
  extend self

  def redis
    @redis ||= begin
      config.connect_directly? ? new_redis! : new_redis_failover!
    end
  end

  def connected?
    redis.get 'raidis-rocks'

  rescue Zookeeper::Exceptions::ZookeeperException, RedisFailover::Error => exception
    @redis = new_redis!
    redis.get 'raidis-rocks'

  rescue *known_redis_connection_exceptions => exception
    unavailable!
  end

  private

  def new_redis!
    return unavailable! unless master = MasterDetector.master

    raw_redis = Redis.new db: config.redis_db, host: master.endpoint, port: master.port
    Redis::Namespace.new config.redis_namespace, redis: raw_redis
  end

  def new_redis_failover!
    RedisFailover::Client.new master_only: true, namespace: config.redis_namespace, zkservers: config.zookeeper_servers, db: config.redis_db, logger: config.logger

  rescue  => exception
    Trouble.notify exception, message: "Could not instantiate a new RedisFailover Client, going over to Plan B, connecting directly to one of #{config.redis_servers}"
    new_redis!
  end

  def known_redis_connection_exceptions
    [Redis::BaseConnectionError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::EAGAIN, Timeout::Error, IOError]
  end

  def known_redis_failover_connection_exceptions
    [Zookeeper::Exceptions::ZookeeperException, RedisFailover::Error]
  end

end
