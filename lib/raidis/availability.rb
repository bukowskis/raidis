module Raidis
  module Availability

    def available?
      if unavailability_age_in_seconds >= config.unavailability_timeout
        available!
      else
        !!@available
      end
    end

    def available!
      @last_availability_check = Time.now
      @available = true
    end

    def unavailable!
      @last_availability_check = Time.now
      @available = false
    end

    private

    def unavailability_age_in_seconds
      return 0 unless @last_availability_check
      (now - @last_availability_check).to_i
    end

    def now
      Time.now
    end

  end
end
