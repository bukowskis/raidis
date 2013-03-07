require 'raidis'

unless defined?(Trouble)
  module Trouble
    def self.notify(*args)
    end
  end
end