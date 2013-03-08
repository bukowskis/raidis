module Raidis
  module Availability

    def available?
      !!@available
    end

    def available!
      @available = true
    end

    def unavailable!
      @available = false
    end

  end
end
