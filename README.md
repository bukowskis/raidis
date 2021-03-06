[![Gem version](https://img.shields.io/gem/v/raidis.svg)](https://rubygems.org/gems/raidis)
[![Build Status](https://travis-ci.org/bukowskis/raidis.png)](https://travis-ci.org/bukowskis/raidis)

# Raid-is

Raidis is yet another failover solution for Redis.

## Why not use RedisFailover?

* Firstly, because RedisFailover may fail itself (it depends on Zookeeper, remember?), while the Redis server is perfectly healthy (been there, done that)
* Seondly, RedisFailover is utterly incompatible with the thread'n'fork chaos introduced by Sidekiq/Resque workers
* We propose that your Redis failover solution is independent of Ruby, because you may have an app using Redis which simply is not a ruby app.

## How do I get started?

Raidis knows where the redis master is by checking the file `/etc/redis_master` and there looking for content such as `127.0.0.1:6379` (you can omit the port if you like to). Note that you can use a RedisFailover daemon to update that file if you wish (or whichever solution you come up with). At any rate, you won't need to use `Redis.new` or `RedisFailover.new` anymore. You'll find your ready-to-go redis in `Raidis.redis` with zero-configuration in your application.

```bash
# Bash
echo "127.0.0.1:6379" > /etc/redis_master
```

```ruby
# Ruby application
require 'raidis'
Raidis.redis.get('some_key')

Raidis.redis.class # => Redis::Namespace
```

# How does it work?

Whenever you call `Raidis.redis`, the connectivity to the remote redis server is monitored. If connectivity problems occur, or you're trying to make write-calls to a Redis slave, Raidis will immediately reload the `/etc/redis_master` file and try to perform the call to Redis again (hoping to have connected to a working redis server this time). If that second attempt failed (or you set `config.retries` to `0`) a `Raidis::ConnectionError` is raised. To prevent too many retries in too short time, there is a minimum interval that Radis will wait after every retry attempt (see config `retry_interval`, default is 3 seconds).

You should not have too many retries, because you don't want the end user's browser to hang and wait too long. That's where the `#available?` feature comes in. As soon as one of those connection errors occurs, the global variable `Raidis.available?` turns from `true` to `false` and any further damage can be mitigated, by simply not making any further calls to redis. You should inform your end-users about the outage in a friendly manner. E.g. like so:

```ruby
if Raidis.available?
   counter = Raidis.redis.get('visits')
else
   counter = "Sorry, the visits counter is not available right now."
end
```

Note that it is one of the design goals of this gem that there are no performance penalties when using `.available?`.

After 15 seconds (or whichever timeout you configure), `Raidis.available?` turns to `true` again automatically and the file `/etc/redis_master` is read again in order to find the remote redis server. If you wish, you may use `Raidis.reconnect!` to evoke the end of that unavailability period manually.

# Connection Pools

If you need to maintain a ConnectionPool with multiple connections to Redis (e.g. when you use [Sidekiq](https://github.com/mperham/sidekiq/issues/794)), you may use the something like `ConnectionPool.new { Raidis.redis! }` (note the exclamation mark) to populate your pool. `.redis!` returns a new connection each time you call it. Note that `Raidis.available?` is a global variable, so if any of the pools fail, Raidis will go into unavailable mode as described above.

## Configuration

Example:

```ruby
Raidis.configure do |config|

  config.logger          = Rails.logger                # default is Rails.logger (if defined) otherwise: Logger.new(STDOUT)
  config.redis_namespace = :myapp                      # default is nil
  config.redis_db        = (Rails.env.test? ? 1 : 0)   # default is whatever Redis.new has as default
  config.redis_timeout   = 3  # seconds                # default is whatever Redis.new has as default

  config.retries = 3  # times                          # default is 1
  config.retry_interval = 3  # seconds                 # default is 3
  config.unavailability_timeout = 60  # seconds        # default is 15 seconds
  config.info_file_path         = '/opt/redis_server'  # default is '/etc/redis_master'

  # You can override the info_file content if you like
  config.master = '127.0.0.1'                          # if omitted, the content of /etc/redis_master is used
end
```
