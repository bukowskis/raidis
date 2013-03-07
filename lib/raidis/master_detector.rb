require 'ostruct'

module Raidis
  class MasterDetector

    BaseError            = Class.new(RuntimeError)
    NoRedisMaster        = Class.new(BaseError)
    MultipleRedisMasters = Class.new(BaseError)

    def Server < OpenStruct
      def master?
        !!self.master
      end
    end

    def master
      masters = masters!
      if masters.empty?
        raise NoRedisMaster
      elsif masters.size > 1
        raise MultipleRedisMasters
      else
        masters.first
      end
    end

    private

    def masters!
      servers!.select(&:master?)
    end

    def servers!
      config.redis_servers.to_s.split(',').map do |redis_server|
        server = Server.new
        server.endpoint, server.port = server.split(':')
        begin
          Timeout::timeout(1) do
            server.is_master = Redis.new(host: server.endpoint, port: server.port).info['role'] == 'master'
          end
        rescue *known_redis_connection_exceptions => exception
          config.logger.info "Raidis::MasterDetector could not connect to #{server.endpoint}:#{server.port}... #{exception}"
        end
        server
      end
    end

  end
end
