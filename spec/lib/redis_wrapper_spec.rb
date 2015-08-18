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

RSpec.describe Raidis::RedisWrapper do

  let(:config)        { double(:config, retries: 3, retry_interval: 0) }
  let(:backend)       { double(:backend) }
  let(:shaky_backend) { ShakyRedis.new }
  let(:wrapper)       { Raidis::RedisWrapper.new }

  before do
    allow(wrapper).to receive(:config).and_return config
  end

  describe '#method_missing' do
    context 'with a stable connection' do
      before do
        allow(wrapper).to receive(:redis!).and_return backend
      end

      it 'proxies everything to the backend' do
        expect(backend).to receive(:any_redis_command).with(:some_key).and_return 'value'
        expect(wrapper.any_redis_command(:some_key)).to eq('value')
      end

      it 'passes on Exceptions from the backend' do
        expect(backend).to receive(:invalid_redis_command).and_raise Redis::CommandError
        expect { wrapper.invalid_redis_command }.to raise_error(Redis::CommandError)
      end

      it 'raises a Raidis::ConnectionError if the backend could not be instantiated' do
        allow(wrapper).to receive(:redis)
        expect { wrapper.redis_command }.to raise_error(Raidis::ConnectionError)
      end

      it 'wraps the call in reloading_connection' do
        expect(wrapper).to receive(:reloading_connection).with(no_args()).and_return 'some_value'
        expect(wrapper.get(:some_key)).to eq('some_value')
      end

      it 'wraps the call in observing_connection' do
        expect(wrapper).to receive(:observing_connection).with(no_args()).and_return 'some_value'
        expect(wrapper.get(:some_key)).to eq('some_value')
      end
    end

    context 'with an unstable connection' do
      before do
        allow(wrapper).to receive(:redis!).and_return shaky_backend
      end

      it 'retrieves the result even when the backend fails several times' do
        expect(wrapper.some_redis_command).to eq(:shaky_result)
      end

      context 'with a retry interval' do
        before do
          allow(config).to receive(:retry_interval).and_return 10
        end

        it 'waits some time before each retry' do
          expect(wrapper.throttle).to receive(:sleep).exactly(2).times.with(10)
          Timecop.freeze
          expect(wrapper.some_redis_command).to eq(:shaky_result)
        end

        context 'when running out of retries' do
          before do
            allow(config).to receive(:retries).and_return 1
          end

          it 'finally raises a unified connection error' do
            expect(wrapper.throttle).to receive(:sleep).with(10)
            Timecop.freeze
            expect { wrapper.some_redis_command }.to raise_error(Raidis::ConnectionError)
          end
        end
      end
    end
  end

end


