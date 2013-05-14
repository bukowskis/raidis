module Raidis
  class Throttle

    attr_reader :interval, :last_action

    def initialize(seconds = 3)
      @interval = seconds.to_i
    end

    def sleep_if_needed
      return unless last_action
      duration = last_action + interval - Time.now
      return unless duration.to_i > 0
      sleep duration
    end

    def action!
      @last_action = Time.now
    end

  end
end
