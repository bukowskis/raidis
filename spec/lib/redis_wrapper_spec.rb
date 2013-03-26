require 'spec_helper'

class ShakyRedis
  def initialize(failures = 3)
    @failures = 3
  end

  def perform
    @calls ||= 0
    if @calls < @failures
      @calls += 1
      raise Errno::ECONNREFUSED
    end
    :shaky_result
  end

  def method_missing(method, *args, &block)
    perform
  end
end

describe Raidis::RedisWrapper do

  let(:config)        { mock(:config, retries: 3) }
  let(:backend)       { mock(:backend) }
  let(:shaky_backend) { ShakyRedis.new }
  let(:wrapper)       { Raidis::RedisWrapper.new }

  before do
    wrapper.stub!(:config).and_return config
  end

  describe '#method_missing' do
    context 'with a stable connection' do
      before do
        wrapper.stub!(:redis!).and_return backend
      end

      it 'proxies everything to the backend' do
        backend.should_receive(:any_redis_command).with(:some_key).and_return 'value'
        wrapper.any_redis_command(:some_key).should == 'value'
      end

      it 'passes on Exceptions from the backend' do
        backend.should_receive(:invalid_redis_command).and_raise Redis::CommandError
        expect { wrapper.invalid_redis_command }.to raise_error(Redis::CommandError)
      end

      it 'raises a Raidis::ConnectionError if the backend could not be instantiated' do
        wrapper.stub!(:redis)
        expect { wrapper.redis_command }.to raise_error(Raidis::ConnectionError)
      end

      it 'wraps the call in reloading_connection' do
        wrapper.should_receive(:reloading_connection).with(no_args()).and_return 'some_value'
        wrapper.get(:some_key).should == 'some_value'
      end

      it 'wraps the call in observing_connection' do
        wrapper.should_receive(:observing_connection).with(no_args()).and_return 'some_value'
        wrapper.get(:some_key).should == 'some_value'
      end
    end

    context 'with an unstable connection' do
      before do
        wrapper.stub!(:redis!).and_return shaky_backend
      end

      it 'retrieves the result even when the backend fails several times' do
        wrapper.some_redis_command.should == :shaky_result
      end

      context 'when running out of retries' do
        before do
          config.stub!(:retries).and_return 2
        end

        it 'finally raises a unified connection error' do
          expect { wrapper.some_redis_command }.to raise_error(Raidis::ConnectionError)
        end
      end
    end
  end

end


