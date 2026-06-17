module Swimmy
  module Resource
    class MeetingEvent
      TYPE_CONS = "検討打合せ"
      TYPE_COLL = "談話会"
      OTHER = "その他"

      def initialize(name, date)
        unless name.is_a?(String)
          raise ArgumentError, "Event name must be a string"
        end
        unless date.is_a?(DateTime)
          raise ArgumentError, "Event date must be a DateTime object"
        end

        @name = name
        @type = self.class.name_to_type(name)
        @date = date
      end

      def self.name_to_type(name)
        if name.nil?
          raise ArgumentError, "Type name cannot be nil"
        end
        unless name.is_a?(String)
          raise ArgumentError, "Type name must be a string"
        end 

        if name.include?(TYPE_CONS)
          return TYPE_CONS
        elsif name.include?(TYPE_COLL)
          return TYPE_COLL
        else
          return OTHER
        end
      end

      def name
        @name
      end

      def type
        @type
      end

      def date
        @date
      end
    end # class MeetingEvent
  end # module Resource
end # module Swimmy