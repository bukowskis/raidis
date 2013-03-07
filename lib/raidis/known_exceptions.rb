require 'zookeeper'
require 'redis_failover'

module Raidis
  module KnownExceptions
    extend self

    def redis_connection
      [Redis::BaseConnectionError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::EAGAIN, Timeout::Error, IOError]
    end

    def redis_failover_connection
      [Zookeeper::Exceptions::ZookeeperException, RedisFailover::Error]
    end

    def any_connection_related
      redis_failover_connection + redis_connection
    end

  end
end
