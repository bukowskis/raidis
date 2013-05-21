require_relative '../../../lib/raidis/configuration'

describe Raidis::Configuration do

  let(:config) { Raidis::Configuration.new }

  it "uses /etc/redis_master as default redis info file" do
    config.info_file_path.to_s.should == '/etc/redis_master'
  end

  it "uses the given file as redis info file" do
    config.info_file_path = '/foo/bar'
    config.info_file_path.to_s.should == '/foo/bar'
  end
end
