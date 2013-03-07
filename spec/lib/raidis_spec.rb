require 'spec_helper'

describe Raidis do

  let(:info_file_path) { mock(:info_file_path, exist?: true, readable?: true, read: '127.0.0.1') }
  let(:raidis)         { Raidis }
  let(:redis)          { raidis.redis }

  before do
    Raidis.config.stub!(:info_file_path).and_return info_file_path
    Raidis.config.stub!(:redis_database).and_return 16  # Just making sure we don't mess anything up in Production
  end

  after do
    Raidis.reset!
  end

  context 'when connected' do
    context 'to a Redis master' do

      describe '.available?' do
        it 'returns true' do
          raidis.should be_available
        end
      end
    end

    context 'to a Redis slave' do
      before do
        redis.slaveof '127.0.0.1', 123
      end

      describe '.available?' do
        it 'becomes unavailable ' do
          Trouble.should_receive(:notify) do |args|
            args.last.should == 'asd'
          end
          expect { redis.setex(:writing, 1, :against_a_slave) }.to raise_error(Redis::CommandError)
          raidis.should_not be_available
        end
      end
    end
  end

end
