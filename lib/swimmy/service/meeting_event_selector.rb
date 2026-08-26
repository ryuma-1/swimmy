require 'date'

module Swimmy
  module Service
    class MeetingEventSelector
      def initialize(cal_gateway)
        if cal_gateway.nil?
          raise ArgumentError, "cal_gateway cannot be nil"
        end
        unless cal_gateway.is_a?(Swimmy::Service::GoogleCalendarGateway)
          raise ArgumentError, "cal_gateway must be a GoogleCalendarGateway object"
        end

        @cal_gateway = cal_gateway
      end

      def select(date = Date.today)
        unless date.is_a?(Date)
          raise ArgumentError, "Date must be a Date object"
        end

        events = @cal_gateway.date_to_events(date)

        # 予定がない場合は NullMeetingEvent を返す
        if events.empty?
          return nil
        end

        # 検討打合せのイベントを特定
        # 1つのグループに対して1日に2つ以上の検討打合せがある場合は考慮していない
        meet_event = events
          .find { |e| e.summary.include?(Swimmy::Resource::MeetingEvent::CONSIDERATION) }

        meet_event&.then { |e| Swimmy::Resource::MeetingEvent.new(e.summary, e.start) }
      end # access
    end # class MeetingEventSelector
  end # module Service
end # module Swimmy
