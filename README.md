# Raid-is

Raidis is yet another failover solution for Redis.

## Why not use RedisFailover?

* Firstly, because RedisFailover may fail itself (it depends on a Zookeeper cluster, remember?), while the Redis server is perfectly healthy
* Seondly, RedisFailover is utterly incompatible with the thread'n'fork chaos introduced by Resque workers
* Thirdly, if you have but one single application not using Ruby, you'll have to come up with a _global_ failover solution anyway

## Okay, how do I get started?

Raidis knows where the redis master is by checking the file `/etc/redis_master` and there looking for content such as `127.0.0.1:6379`. Note that you can use a RedisFailover daemon to update that file if you wish. At any rate, you won't need to use `Redis.new` or `RedisFailover.new` anymore. You'll find your ready-to-go redis in `Raidis.redis` with zero-configuration in your application.

```bash
echo "127.0.0.1:6379" > /etc/redis_master
```

```ruby
require 'raidis'
Raidis.redis.get('some_key')

Raidis.redis.class # => Redis::Namespace
```

# How does it work?

Whenever you call `Raidis.redis`, the connectivity to the remote redis server is monitored. If connectivity problems occur, or you're trying to make write-calls to a Redis slave, a `Raidis::ConnectionError` is raised.

As soon as one of those connection errors occurs, the global variable `Raidis.available?` turns from `true` to `false` and any further damage can be mitigated, by simply not making any further calls to redis. You should inform your end-users about the outage in a friendly manner. E.g. like so:

```ruby
if Raidis.available?
   counter = Raidis.redis.get('visits')
else
   counter = "Sorry, the visits counter is not available right now."
end
```

Note that it is one of the design goals of this gem that there are no performance penalties when using `#available?`.

After 15 seconds (or whichever timeout you configure), `Raidis.available?` turns to `true` again automatically and the file `/etc/redis_master` is read again in order to find the remote redis server.

## Configuration

```ruby
Raidis.configure do |config|

  config.logger          = Rails.logger                # default is Logger.new(STDOUT)
  config.redis_namespace = :myapp                      # default is nil

  config.redis_db        = (Rails.env.test? ? 1 : 0)   # default is whatever Redis.new has as default
  config.redis_timeout   = 3  # seconds                # default is whatever Redis.new has as default

  config.info_file_path  = '/opt/redis_server'         # default is '/etc/redis_master'
  config.unavailability_timeout = 60  # seconds        # default is 15 seconds

end
```
