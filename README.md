# Raid-is

Raidis is a wrapper for [redis_failover](https://github.com/ryanlecompte/redis_failover). It's called `Raidis`, because `redis_failover_failover` sounded silly. Besides, I want it to be flexible enough to wrap around further libraries in the future.

You won't need to use `Redis.new` or `RedisFailover.new` anymore. You'll find your ready-to-go redis in `Raidis.redis`.

However, wherever you use plan on using Redis in your application, make sure to first check the connection like so:

```ruby
if Raidis.available?
   counter = Raidis.redis.get('visits')
else
   counter = "Sorry, the counter is not available right now."
end
```

Note that it is one of the design goals of this gem that there are no performance penalties when using `#available?`.

# How does it work?

There are two ways where you may get into trouble when Redis goes down.

#### 1. Redis is not reachable at instantiation (i.e. Rails bootup)

Really what you want is to boot your application anyway. Your application should handle that Redis is not available and show some friendly error message to the end user.

So if you're using RedisFailover with Zookeeper, either the Zookeeper cluster, **or** the Redis master may fail. Raidis is here to help you find a suitable Redis server even if the Zookeeper cluster goes into a funky state. If the Redis master cannot even be found manually, `Raidis.available?` will be false and your application will handle it.

```ruby
Raidis.configure do |config|

  # Endpoints to the actual Redis cluster.
  config.redis_servers = '172.10.0.0:6379,172.20.0.0:6379'  # mandatory

  # Endpoints to the Zookeepers
  config.zookeeper_servers = '127.0.0.1:2181,192.168.0.1:2181'  # required if connect_directly is false

  # Self-explanatory values
  config.logger          = Rails.logger               # default is Logger.new(STDOUT)
  config.redis_db        = (Rails.env.test? ? 1 : 0)  # default is 0
  config.redis_namespace = :myapp                     # default is nil
end
```

### A note on Resque

Resque is not really compatible with RedisFailover. In that case, add this configuration option to skip the failover:

```ruby
Raidis.configure do |config|
  config.connect_directly = true  # default is false
end
```

Note that if you set [Resque.redis](https://github.com/defunkt/resque/blob/master/lib/resque.rb#L49) you need to be very careful with the namespacing.

```ruby
Resque.redis = Redis::Namespace.new :resque, redis: Raidis.redis
```



#### 2. Redis becomes unreachable during operation (i.e. Rails has booted)



# Usage

#### Syntax

```ruby
```

#### Examples

```ruby
```
