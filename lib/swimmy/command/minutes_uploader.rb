module Swimmy
  module Command
    class MinutesUploader < Swimmy::Command::Base
      command "minutes_uploader" do |client, data, match|

        # 1. Google OAuth の認証
        google_oauth = 
          begin
            Swimmy::Resource::GoogleOAuth.new('config/credentials.json', 'config/tokens.json')
          rescue => e
            puts "OAuth Error: #{e.message}"
            client.say(channel: data.channel, text: "Google OAuthの認証に失敗しました．設定を確認してください．")
            next 
          end

        client.say(channel: data.channel, text: "OAuth認証成功")

        # 2. 予定の取得処理
        begin
          # NOTE: spreadsheet オブジェクトの取得方法が環境に依存するため、
          # Swimmyの仕様に合わせて spreadsheet を定義する必要があります。
          # 例: sheet = spreadsheet.sheet("calendar", Swimmy::Resource::Calendar)
          
          # 以下は構造の修正例です
          sheet = spreadsheet.sheet("calendar", Swimmy::Resource::Calendar)
          calendars = sheet.fetch
          calendars_num = calendars.size

          client.say(channel: data.channel, text: "予定の取得に成功しました．#{calendars_num}件の予定が見つかりました．")

          calendars.each do |calendar|
            client.say(channel: data.channel, text: "Calendar: #{calendar.name} (ID: #{calendar.id})")
          end

          cal_service = Swimmy::Service::CalendarGateway.new(calendars)
          client.say(channel: data.channel, text: "サービス取得完了")

          events = cal_service.date_to_events(Date.today)

          events.each do |event|
            client.say(channel: data.channel, text: "Event: #{event.summary} at #{event.start} (#{event.calendar_name})")
          end

        rescue => e
          client.say(channel: data.channel, text: "エラーが発生しました: #{e.message}")
        end # begin-rescue の終わり
      end # command "minutes_uploader" の終わり
    end # class MinutesUploader の終わり
  end # module Command
end # module Swimmy
