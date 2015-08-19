require 'raidis'
require 'timecop'

RSpec.configure do |config|

  config.raise_errors_for_deprecations!
  config.disable_monkey_patching!
  config.color = true

  config.before do
    stub_const 'Trouble', double(:trouble)
    allow(Trouble).to receive :log
    allow(Trouble).to receive :notify

    Raidis.configure do |config|
      config.redis_db = 15
      config.redis_timeout = 0.1
      config.retry_interval = 0
    end

    Raidis.configure(:other) do |config|
      config.redis_db = 14
      config.redis_timeout = 0.1
      config.retry_interval = 0
    end

    pathname = double :info_file_path, exist?: true, readable?: true, read: '127.0.0.1'
    allow(Raidis.config).to receive(:info_file_path).and_return pathname
    allow(Raidis.config(:other)).to receive(:info_file_path).and_return pathname
  end

  config.after do
    Raidis.reset_configuration!
    Raidis.reconnect!
    Timecop.return
  end

end
