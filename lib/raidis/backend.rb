require 'raidis/known_exceptions'
require 'raidis/master_detector'

module Raidis
  module Backend
    extend self

    def manual_redis
      unless master = MasterDetector.master
        Raidis.unavailable!
        return
      end

      raw_redis = Redis.new db: db, host: master.endpoint, port: master.port
      Redis::Namespace.new namespace, redis: raw_redis

    rescue MasterDetector::BaseError
      nil
    end

    def redis_failover
      RedisFailover::Client.new master_only: true, namespace: namespace, zkservers: zkservers, db: db, logger: logger

    rescue *KnownExceptions.redis_failover_connection, RuntimeError => exception
      Trouble.notify(exception, message: "Could not instantiate a new RedisFailover Client, going over to Plan B, connecting directly to a Redis Master.") if defined?(Trouble)
      manual_redis
    end

    private

    def db
      Raidis.config.redis_db
    end

    def namespace
      Raidis.config.redis_namespace
    end

    def zkservers
      Raidis.config.zookeeper_servers
    end

    def logger
      Raidis.config.logger
    end

  end
end
