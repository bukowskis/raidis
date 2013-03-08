require 'spec_helper'

describe Raidis do

  let(:raidis)         { Raidis }
  let(:redis)          { raidis.redis }

  context 'when connected' do
    context 'to a Redis master' do
      before do
        redis.slaveof :no, :one
      end

      describe '.redis' do
        it 'is is a RedisWrapper' do
          redis.should be_instance_of Raidis::RedisWrapper
        end

        it 'lets through command errors unrelated to the connection' do
          expect { redis.setex(:invalid, -1, :parameters) }.to raise_error(Redis::CommandError)
        end
      end

      describe '.connected?' do
        it 'is true' do
          raidis.should be_connected
        end
      end

      describe '.available?' do
        it 'is true' do
          raidis.should be_available
        end
      end
    end

    context 'to a Redis slave' do
      before do
        redis.slaveof '127.0.0.1', 12345
      end

      describe '.redis' do
        it 'detects illegal writes to a slave' do
          Trouble.should_receive(:notify) do |exception, metadata|
            exception.should be_instance_of Redis::CommandError
            metadata[:code].should == :readonly
          end
          expect { redis.setex(:writing, 1, :against_a_slave) }.to raise_error(Raidis::ConnectionError)
        end

        it 'is fine with read-only commands' do
          redis.get(:some_key).should be_nil
        end

        it 'lets through command errors unrelated to the connection' do
          expect { redis.lrange(:invalid, :command, :arguments) }.to raise_error(Redis::CommandError)
        end
      end

      describe '.connected?' do
        it 'is false' do
          raidis.should_not be_connected
        end
      end

      describe '.available?' do
        it 'is false' do
          raidis.should_not be_available
        end
      end
    end
  end

  context 'when not connected' do
    context 'because the Network is unreachable' do
      before do
        Raidis.config.stub!(:info_file_path).and_return mock(:info_file_path, exist?: true, readable?: true, read: '192.0.2.1')  # RFC 5737
        Raidis.reconnect!
      end

      describe '.redis' do
        it 'detects that there is no connection' do
          Trouble.should_receive(:notify) do |exception, metadata|
            exception.should be_instance_of Redis::CannotConnectError
            metadata[:code].should == :lost_connection
          end
          expect { redis.get(:some_key) }.to raise_error(Raidis::ConnectionError)
        end
      end

      describe '.connected?' do
        it 'is false' do
          raidis.should_not be_connected
        end
      end

      describe '.available?' do
        it 'is false' do
          raidis.should_not be_available
        end
      end
    end

    context 'because of a wrong port' do
      before do
        Raidis.config.stub!(:info_file_path).and_return mock(:info_file_path, exist?: true, readable?: true, read: '127.0.0.1:80')
        Raidis.reconnect!
      end

      describe '.redis' do
        it 'detects that there is no connection' do
          Trouble.should_receive(:notify) do |exception, metadata|
            exception.should be_instance_of Redis::CannotConnectError
            metadata[:code].should == :lost_connection
          end
          expect { redis.get(:some_key) }.to raise_error(Raidis::ConnectionError)
        end
      end

      describe '.connected?' do
        it 'is false' do
          raidis.should_not be_connected
        end
      end

      describe '.available?' do
        it 'is false' do
          raidis.should_not be_available
        end
      end
    end
  end

end
