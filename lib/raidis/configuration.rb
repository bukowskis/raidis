module Raidis
  class Configuration

    InfoFilePathNotFound = Class.new(RuntimeError)

    class Master
      attr_accessor :endpoint
      attr_writer :port

      def port
        @port ||= 6379
      end
    end

    attr_accessor :redis_namespace, :redis_timeout, :redis_db
    attr_writer :logger, :unavailability_timeout, :master, :retries

    def logger
      @logger ||= begin
        if defined?(Rails)
          Rails.logger
        else
          Logger.new(STDOUT)
        end
      end
    end

    def info_file_path
      @info_file_path ||= Pathname.new('/etc/redis_master')
    end

    def info_file_path=(path)
      Pathname.new path
    end

    def unavailability_timeout
      @unavailability_timeout ||= 15  # seconds
    end

    def retries
      @retries ||= 1
    end

    def master
      unless @master
        unless info_file_path.exist?
          Trouble.notify(InfoFilePathNotFound.new, code: :info_file_not_found, message: 'Raidis could not find the redis master info file', location: info_file_path) if defined?(Trouble)
          return
        end

        unless info_file_path.readable?
          Trouble.notify(InfoFilePathNotFound.new, code: :info_file_not_readable, message: 'The redis master info file exists but is not readable for Raidis', location: info_file_path) if defined?(Trouble)
          return
        end
      end

      content = @master || info_file_path.read
      server = Master.new
      server.endpoint, server.port = content.strip.to_s.split(':')

      unless server.endpoint
        if @master
          Trouble.notify(InfoFilePathNotFound.new, code: :invalid_master, message: 'Raidis does not understand the config.master value you provided', value: config.master.inspect) if defined?(Trouble)
        else
          Trouble.notify(InfoFilePathNotFound.new, code: :invalid_info_file_content, message: 'Raidis found the redis master info file, but there was no valid endpoint in it', location: info_file_path, content: info_file_path.read.inspect) if defined?(Trouble)
        end
        return
      end
      server
    end
  end
end

module Raidis
  extend self

  def config
    @config ||= Configuration.new
  end

  def configure(&block)
    yield config
  end

  def reset!
    config = nil
    reconnect!
  end
end
