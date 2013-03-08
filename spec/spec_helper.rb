require 'raidis'

def ensure_class_or_module(full_name, class_or_module)
  full_name.to_s.split(/::/).inject(Object) do |context, name|
    begin
      context.const_get(name)
    rescue NameError
      if class_or_module == :class
        context.const_set(name, Class.new)
      else
        context.const_set(name, Module.new)
      end
    end
  end
end

def ensure_module(name)
  ensure_class_or_module(name, :module)
end

def ensure_class(name)
  ensure_class_or_module(name, :class)
end

ensure_module :Trouble

RSpec.configure do |config|

  # Global before hook
  config.before do
    Trouble.stub!(:notify)

    Raidis.configure do |config|
      config.redis_db = 15
      config.redis_timeout = 0.5
    end
    Raidis.config.stub!(:info_file_path).and_return mock(:info_file_path, exist?: true, readable?: true, read: '127.0.0.1')
  end

  # Global after hooks
  config.after do
    Raidis.reset!
  end

end
