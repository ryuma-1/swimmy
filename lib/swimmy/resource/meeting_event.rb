module Swimmy
  module Resource
    class MeetingEvent
      CONSIDERATION = "検討打合せ"

      def initialize(name, date)
        unless name.is_a?(String)
          raise ArgumentError, "Event name must be a string"
        end
        unless date.is_a?(DateTime)
          raise ArgumentError, "Event date must be a DateTime object"
        end

        @name = name
        @date = date
        @count = self.class.name_to_count(name)
      end

      def event_info
        "Event Name: #{@name}, Date: #{@date}, Count: #{@count}"
      end

      def name
        @name
      end

      def date
        @date
      end

      def count
        @count
      end

      private

      def self.name_to_count(name)
        case name
        when /第(\d+)回/
          $1.to_i
        else
          raise ArgumentError, "Invalid event name format: #{name}"
        end
      end

    end # class MeetingEvent
  end # module Resource
end # module Swimmy
