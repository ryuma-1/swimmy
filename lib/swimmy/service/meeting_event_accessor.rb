
module Swimmy
  module Service
    class MeetingEventAccessor
      def access()
        events = []
        begin
          # spreadsheet オブジェクトの取得
          sheet = spreadsheet.sheet("calendar", Swimmy::Resource::Calendar)
          calendars = sheet.fetch
          target_calendar = calendars[index]

          if target_calendar.nil?
            raise "カレンダーが見つかりません: #{name} (インデックス: #{index})"
          end

          cal_service = Swimmy::Service::CalendarGateway.new(target_calendar)
          events = cal_service.date_to_events(Date.today)
        rescue => e
          client.say(channel: data.channel, text: "イベントの取得に失敗しました: #{e.message}")
          next
        end

        # 予定がない場合はその旨を伝えて終了
        if events.empty?
          client.say(channel: data.channel, text: "【#{name}】#{Date.today}のイベントはありません．")
          next
        end

        # 検討打合せのイベントを特定
        begin
        meet_event = events
          .map { |event| Swimmy::Resource::MeetingEvent.new(event.summary, event.start) }
          .find { |e| e.type == Swimmy::Resource::MeetingEvent::TYPE_CONS }
        rescue => e
          client.say(channel: data.channel, text: "検討打合せのイベントの取得に失敗しました: #{e.message}")
          next
        end

        return meet_event
      end # def create
    end # class CalendarGateway
  end # module Service
end # module Swimmy
