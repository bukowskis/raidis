require_relative '../../../lib/raidis/configuration'

RSpec.describe Raidis::Configuration do

  let(:config) { Raidis::Configuration.new }

  it "uses /etc/redis_master as default redis info file" do
    expect(config.info_file_path.to_s).to eq('/etc/redis_master')
  end

  it "uses the given file as redis info file" do
    config.info_file_path = '/foo/bar'
    expect(config.info_file_path.to_s).to eq('/foo/bar')
  end
end
