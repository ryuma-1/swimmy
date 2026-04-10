module Swimmy
  module Command
    class MinutesUploader < Swimmy::Command::Base
      # 定数はクラスの直下に置くのが一般的です
      MINUTE_TYPES = {
        gn:  1,
        new: 2 
      }.freeze

      command "minutes_uploader" do |client, data, match|
        # 1. Google OAuth の認証
        begin
          google_oauth = Swimmy::Resource::GoogleOAuth.new('config/credentials.json', 'config/tokens.json')
        rescue => e
          client.say(channel: data.channel, text: "Google OAuthの認証に失敗しました．")
          next 
        end

        # 2. 予定の取得処理
        begin
          # spreadsheet オブジェクトの取得（環境に合わせて調整してください）
          sheet = spreadsheet.sheet("calendar", Swimmy::Resource::Calendar)
          calendars = sheet.fetch

          client.say(channel: data.channel, text: "予定の取得に成功しました．#{calendars.size}件の予定が見つかりました．")

          # ハッシュ（辞書）をループして処理
          MINUTE_TYPES.each do |name, index|
            target_calendar = calendars[index]
            client.say(channel: data.channel, text: "Processing calendar: #{target_calendar.name} (ID: #{target_calendar.id})")

            # カレンダーが存在しない場合のガード
            next unless target_calendar

            cal_service = Swimmy::Service::CalendarGateway.new([target_calendar])
            events = cal_service.date_to_events(Date.today)

            if events.empty?
              client.say(channel: data.channel, text: "【#{name}】本日のイベントはありません．")
            else
              events.each do |event|
                client.say(channel: data.channel, text: "【#{name}】Event: #{event.summary} at #{event.start}")
              end
            end
          end

        rescue => e
          client.say(channel: data.channel, text: "エラーが発生しました: #{e.message}")
          puts e.backtrace
        end
      end
    end
  end
end
