require 'raidis/throttle'

module Raidis
  class RedisWrapper

    # Public: Proxies everything to the Redis backend.
    #
    # Returns whatever the backend returns.
    # Raises Raidis::ConnectionError if there is a connection problem.
    #
    def method_missing(method, *args, &block)
      raise(Raidis::ConnectionError, 'No Redis backend found.') unless redis
      reloading_connection do
        observing_connection { redis.send(method, *args, &block) }
      end
    end

    # Internal: If a Raidis::ConnectionError is detected during the execution of the block,
    # try to reconnect to Redis and try again. Updates the availability state.
    #
    # Returns whatever the block returns.
    # Raises Raidis::ConnectionError if the connection problem persists even after the retries.
    #
    def reloading_connection(&block)
      tries ||= config.retries
      result = block.call
    rescue Raidis::ConnectionError => exception
      # Try again a couple of times.
      throttle.sleep_if_needed
      if (tries -= 1) >= 0
        throttle.action!
        reconnect!
        retry
      end
      # Giving up.
      Raidis.unavailable!
      raise exception
    else
      # No exception was raised, reaffirming the availability.
      Raidis.available!
      result
    end

    # Internal: Raises a Raidis::ConnectionError if there are connection-related problems during the execution of the block.
    # More specifically, if the connection is lost or a write is performed against a slave, the Exception will be raised.
    #
    def observing_connection(&block)
      yield

    rescue *connection_errors => exception
      Trouble.notify(exception, code: :lost_connection, message: 'Raidis lost connection to the Redis server.', client: redis.inspect) if defined?(Trouble)
      raise Raidis::ConnectionError, exception

    rescue Redis::CommandError => exception
      if exception.message.to_s.split.first == 'READONLY'
        Trouble.notify(exception, code: :readonly, message: 'Raidis detected an illegal write against a Redis slave.', client: redis.inspect) if defined?(Trouble)
        raise Raidis::ConnectionError, exception
      else
        # Passing through Exceptions unrelated to the Connection. E.g. Redis::CommandError.
        raise exception
      end
    end

    # Internal: A list of known connection-related Exceptions the backend may raise.
    #
    def connection_errors
      [
        Redis::BaseConnectionError,
        IOError,
        Timeout::Error,
        Errno::EADDRNOTAVAIL,
        Errno::EAGAIN,
        Errno::EBADF,
        Errno::ECONNABORTED,
        Errno::ECONNREFUSED,
        Errno::ECONNRESET,
        Errno::EHOSTUNREACH,
        Errno::EINVAL,
        Errno::ENETUNREACH,
        Errno::EPIPE,
      ]
    end

    def reconnect!
      @redis = nil
    end

    def throttle
      @throttle ||= Throttle.new config.retry_interval
    end

    # Internal: Establishes a brand-new, raw connection to Redis.
    #
    # Returns a Redis::Namespace instance or nil if we don't know where the Redis server is.
    #
    def redis
      @redis ||= redis!
    end

    def redis!
      return unless master = config.master
      raw_redis = Redis.new db: config.redis_db, host: master.endpoint, port: master.port, timeout: config.redis_timeout
      Redis::Namespace.new config.redis_namespace, redis: raw_redis
    end

    # Internal: Convenience wrapper
    #
    def config
      Raidis.config
    end
  end
end
