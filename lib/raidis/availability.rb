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
      checking_availability
      @available = true
    end

    def unavailable!
      checking_availability
      @available = false
    end

    private

    def checking_availability
      @last_availability_check = Time.now.to_i
    end

    def unavailability_age_in_seconds
      return 0 unless @last_availability_check
      Time.now.to_i - @last_availability_check.to_i
    end

  end
end
