
module Raidis

  InfoFilePathNotFound = Class.new(RuntimeError)

  class Master
    attr_accessor :endpoint
    attr_writer :port

    def port
      @port ||= 6379
    end
  end

  class Configuration
    attr_accessor :redis_namespace, :redis_timeout
    attr_writer :logger, :redis_db

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def redis_db
      @redis_db ||= 0
    end

    def info_file_path
      @info_file_path ||= Pathname.new('/etc/redis_master')
    end

    def info_file_path=(path)
      Pathname.new path
    end

    def master
      unless info_file_path.exist?
        Trouble.notify(InfoFilePathNotFound.new, message: 'Raidis could not find the redis master info file', location: info_file_path) if defined?(Trouble)
        return
      end

      unless info_file_path.readable?
        Trouble.notify(InfoFilePathNotFound.new, message: 'The redis master info file exists but is not readable for Raidis', location: info_file_path) if defined?(Trouble)
        return
      end

      server = Master.new
      server.endpoint, server.port = info_file_path.read.strip.to_s.split(':')

      unless server.endpoint
        Trouble.notify(InfoFilePathNotFound.new, message: 'Raidis found the redis master info file, but there was no valid endpoint in it', location: info_file_path, content: info_file_path.read.inspect) if defined?(Trouble)
        return
      end
      server
    end
  end

  def self.config
    @config ||= Configuration.new
  end

  def self.configure(&block)
    yield config
  end

end
