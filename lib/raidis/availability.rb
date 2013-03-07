module Raidis
  module Availability

    def available?
      !!@available
    end

    private

    def available!
      @available = true
    end

    def unavailable!
      @available = false
    end

  end
end
