require 'raidis/configuration'
require 'raidis/availability'
require 'raidis/backend'
require 'raidis/connection'

module Raidis
  extend self

  def redis
    @redis ||= begin
      result = config.connect_directly? ? Backend.manual_redis : Backend.redis_failover
      connected?
      result
    end
  end

  # Public: Force an immediate reconnect.
  #         Useful if your webserver gave up looking for Redis and you want it to retry.
  #
  def reset!
    @redis = nil
  end

end
