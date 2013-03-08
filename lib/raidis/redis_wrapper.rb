module Raidis
  class RedisWrapper

    def initialize(object)
      @redis = object
    end

    def method_missing(method, *args, &block)
      failsafe { @redis.send(method, *args, &block) }
    end

    private

    def failsafe(&block)
      yield

    rescue *connection_errors => exception
      Trouble.notify(exception, code: :lost_connection, message: 'Raidis lost connection to the Redis server.', client: redis.inspect) if defined?(Trouble)
      Raidis.unavailable!
      raise Raidis::ConnectionError, exception

    rescue Redis::CommandError => exception
      if exception.message.to_s.split.first == 'READONLY'
        Trouble.notify(exception, code: :readonly, message: 'Raidis detected an illegal write against a Redis slave.', client: redis.inspect) if defined?(Trouble)
        Raidis.unavailable!
        raise Raidis::ConnectionError, exception
      else
        raise exception
      end
    end

    def connection_errors
      [
        Redis::BaseConnectionError,
        IOError,
        Timeout::Error,
        Errno::ENETUNREACH,
        Errno::EHOSTUNREACH,
        Errno::ECONNREFUSED,
        Errno::ECONNRESET,
        Errno::EAGAIN,
        Errno::EPIPE,
        Errno::ECONNABORTED,
        Errno::EBADF,
        Errno::EINVAL
      ]
    end

  end
end
