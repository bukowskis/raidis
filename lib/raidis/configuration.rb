module Raidis

  class Configuration

    attr_accessor :zookeeper_servers, :redis_servers, :redis_namespace
    attr_writer :logger, :redis_db, :connect_directly

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def redis_db
      @redis_db ||= 0
    end

    def connect_directly?
      !!@connect_directly
    end

  end

  def self.config
    @config ||= Configuration.new
  end

  def self.configure(&block)
    yield config
  end

end
