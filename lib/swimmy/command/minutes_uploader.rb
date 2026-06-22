require 'dotenv'

Dotenv.load

module Swimmy
  module Command
    class MinutesUploader < Swimmy::Command::Base
      command "minutes_uploader" do |client, data, match|
        MINUTE_TYPES = %i[GN New].freeze
        MINUTE_CREATE_URL = "https://rask.nomlab.org/documents/new".freeze
jj
        private_constant :MINUTE_TYPES

        MINUTE_TYPES.each do |type|
          # イベントの取得処理
          begin
            sheet = spreadsheet.sheet("calendar", Swimmy::Resource::Calendar)
            cal_gateway = Swimmy::Service::GoogleCalendarGateway.new(type, sheet)
            meet_event_factory = Swimmy::Service::MeetingEventFactory.new(cal_gateway)
            meet_event = meet_event_factory.create(Date.today) || false
          rescue => e
            client.say(channel: data.channel, text: "【#{type}】イベント取得でエラーが発生しました: #{e.message}")
            next
          end

          # イベントが存在しない場合の出力
          if !meet_event
            client.say(channel: data.channel, text: "【#{type}】本日の検討打合せはありません")
            next
          end

          # イベントが存在する場合の出力
          client.say(channel: data.channel, text: "【#{type}】#{meet_event.name} #{meet_event.date}")

          # 前回の議事録のURLを取得するため，検討打合せの回数から1を引いたものをcountとする
          target_minutes_count = meet_event.count - 1

          # 議事録の取得処理
          begin
            minutes_factory = Swimmy::Service::MinutesFactory.new()
            target_minutes = minutes_factory.create(target_minutes_count, type)
          rescue => e
            client.say(channel: data.channel, text: "【#{type}】議事録探索でエラーが発生しました: #{e.message}")
            next
          end

          # 結果をSlackへの出力
          client.say(channel: data.channel, text: "前回の議事録: #{target_minutes.title} #{target_minutes.url}")
          client.say(channel: data.channel, text: "議事録作成: #{MINUTE_CREATE_URL}")
        end
      end
    end # class MinutesUploader
  end # module Command
end # module Swimmy
