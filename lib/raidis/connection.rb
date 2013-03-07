require 'raidis/known_exceptions'

module Raidis

  def connected?
    if connected_via_redis_failover? || connected_manually?
      available!
    else
      unavailable!
    end
  end

  private

  def connected_via_redis_failover?
    return false unless @redis
    try!
    true

  rescue *KnownExceptions.any_connection_related => exception
    @redis = new_manual_redis!
    connected_manually?
  end

  def connected_manually?
    return false unless @redis
    try!
    true
  rescue *KnownExceptions.redis_connection => exception
    unavailable!
    false
  end

  def try!
    redis.get 'raidis-rocks'
  end

end
