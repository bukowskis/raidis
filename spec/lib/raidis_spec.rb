require 'spec_helper'

describe Raidis do

  let(:redis) { Raidis.redis }

  after do
    Raidis.reset!
  end

  context 'Zookeeper is not available' do
    context 'because the server cannot be connected to' do
      before do
        Raidis.config.zookeeper_servers = '127.0.0.1' # Omitted port
      end

      it 'does something' do
        Raidis.redis
      end


    end
  end

  context 'Zookeeper is up and running' do

    before do
      Raidis.configure do |config|
        config.zookeeper_servers = '127.0.0.1'
      end
    end

  end

  describe '.redis' do


  end
end