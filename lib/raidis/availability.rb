module Raidis
  module Availability

    def available?(identifier = :default)
      if unavailability_age_in_seconds >= config.unavailability_timeout
        available! identifier
      else
        !!availables[identifier]
      end
    end

    def available!(identifier = :default)
      checking_availability
      availables[identifier] = true
    end

    def unavailable!(identifier = :default)
      checking_availability
      availables[identifier] = false
    end

    private

    def availables
      @availables ||= {}
    end

    def last_availability_checks
      @last_availability_checks ||= {}
    end

    def checking_availability(identifier = :default)
      last_availability_checks[identifier] = Time.now.to_i
    end

    def unavailability_age_in_seconds(identifier = :default)
      return 0 unless last_availability_checks[identifier]
      Time.now.to_i - last_availability_checks[identifier].to_i
    end

  end
end
