require 'redis/namespace'
require 'timeout'

require 'raidis/availability'
require 'raidis/configuration'

module Raidis
  extend self
  extend Availability

  def redis
    @redis ||= begin
      client = redis!
      connected? client
      client
    end

  rescue *connection_errors => exception
    Trouble.notify(exception, message: 'Raidis lost connection to the Redis server.', client: redis.inspect) if defined?(Trouble)
    unavailable!
    raise exception

  rescue Redis::CommandError => exception
    return @redis unless exception.message.to_s.split.first == 'READONLY'
    Trouble.notify(exception, message: 'Raidis detected an illegal write against a Redis slave.', client: redis.inspect) if defined?(Trouble)
    unavailable!
    # Let the upstream application know that this actually was a connection problem, not a command syntax error or something
    raise Redis::ConnectionError
  end

  def connected?(client = @redis)
    return unavailable! unless client
    client.setex(:raidis, 1, :rocks) && available!

  rescue *connection_errors, Redis::CommandError => exception
    # Knowing that the setex-command is correct, the only possible CommandError is a "READONLY" when writing to a slave
    Trouble.notify(exception, message: 'Raidis just tried to test the connection.', client: client.inspect) if defined?(Trouble)
    unavailable!
  end

  def reset!
    @redis = nil
    redis
  end

  private

  def redis!
    return unless master = config.master
    raw_redis = Redis.new db: config.redis_db, host: master.endpoint, port: master.port
    Redis::Namespace.new config.redis_namespace, redis: raw_redis
  end

  def connection_errors
    [Redis::BaseConnectionError, IOError, Timeout::Error, Errno::EHOSTUNREACH, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EAGAIN, Errno::EPIPE, Errno::ECONNABORTED, Errno::EBADF, Errno::EINVAL]
  end
end
