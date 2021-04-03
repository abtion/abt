# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      class HarvestHelpers
        class << self
          HOURS_REGEX = /(?<hours>\d+)/.freeze
          MINUTES_REGEX = /(?<minutes>[0-5][0-9])/.freeze
          SECONDS_REGEX = /(?<seconds>[0-5][0-9])/.freeze
          TIME_REGEX = /^#{HOURS_REGEX}:#{MINUTES_REGEX}(?::#{SECONDS_REGEX})?$/.freeze

          def decimal_hours_from_string(hh_mm_ss)
            match = TIME_REGEX.match(hh_mm_ss)
            raise Abt::Cli::Abort, "Invalid time: #{hh_mm_ss}, supported formats are: HH:MM, HH:MM:SS" if match.nil?

            match[:hours].to_i +
              match[:minutes].to_i / 60.0 +
              match[:seconds].to_i / 60.0 / 60.0
          end
        end
      end
    end
  end
end
