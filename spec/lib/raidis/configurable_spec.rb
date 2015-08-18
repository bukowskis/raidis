require 'spec_helper'

RSpec.describe Raidis do

  let(:raidis)   { described_class }

  describe '.config' do
    context 'without namespace' do
      it 'is a Configuration' do
        expect(raidis.config).to be_instance_of Raidis::Configuration
      end

      it 'is always the same instance' do
        expect(raidis.config).to be raidis.config
      end
    end

    context 'with namespace' do
      it 'is a Configuration' do
        expect(raidis.config(:special_stuff)).to be_instance_of Raidis::Configuration
      end

      it 'is not the default config' do
        expect(raidis.config(:beautiful)).to_not be raidis.config
      end
    end
  end

  describe '.configure' do
    context 'without namespace' do
      it 'yields the configuration' do
       expect { |b| raidis.configure(&b) }.to yield_with_args raidis.config
      end
    end

    context 'with namespace' do
      it 'yields the namespaced configuration' do
       expect { |b| raidis.configure(:the_other_one, &b) }.to yield_with_args raidis.config(:the_other_one)
      end

      it 'does not yield the default config' do
        expect { |b| raidis.configure(:not_the_default_i_guess, &b) }.to_not yield_with_args raidis.config
      end
    end
  end

  describe '.reset_configuration!' do
    let(:default_config)    { raidis.config }
    let(:namespaced_config) { raidis.config :space }

    it 'resets all configs' do
      expect(raidis.config).to be default_config
      expect(raidis.config(:space)).to be namespaced_config
      raidis.reset_configuration!
      expect(raidis.config).to_not be default_config
      expect(raidis.config(:space)).to_not be namespaced_config
    end
  end

end
