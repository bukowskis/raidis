require 'spec_helper'

RSpec.describe Raidis::Configuration do

  let(:config) { Raidis::Configuration.new }

  context 'default settings' do
    it 'uses /etc/redis_master as default redis info file' do
      expect(config.info_file_path.to_s).to eq '/etc/redis_master'
    end
  end

  context 'custom info file path' do
    before do
      config.info_file_path = '/some/custom/path'
    end

    it 'uses the provided path as upstream file' do
      expect(config.info_file_path.to_s).to eq '/some/custom/path'
    end
  end

end
