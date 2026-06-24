require 'dotenv'

Dotenv.load

module Swimmy
  module Command
    class MinutesUploader < Swimmy::Command::Base
      MINUTE_TYPES = %i[GN New].freeze
      MINUTE_CREATE_URL = "https://rask.nomlab.org/documents/new".freeze
      private_constant :MINUTE_TYPES, :MINUTE_CREATE_URL

      command "minutes_uploader" do |client, data, match|

        # sheet の取得
        sheet = spreadsheet.sheet("calendar", Swimmy::Resource::Calendar)

        MINUTE_TYPES.each do |type|
          # イベントの取得処理
          begin
            cal_gateway = Swimmy::Service::GoogleCalendarGateway.new(type, sheet)
            meet_event_accessor = Swimmy::Service::MeetingEventAccessor.new(cal_gateway)
            meet_event = meet_event_accessor.create(Date.today)
          rescue => e
            client.say(channel: data.channel, text: "【#{type}】イベント取得でエラーが発生しました: #{e.message}")
            next
          end

          # イベントが存在しない場合の出力
          if meet_event.nil?
            client.say(channel: data.channel, text: "【#{type}】本日の検討打合せはありません")
            next
          end

          # イベントが存在する場合の出力
          client.say(channel: data.channel, text: "【#{type}】#{meet_event.name} #{meet_event.date}")

          # 前回の議事録のURLを取得するため，検討打合せの回数から1を引いたものをcountとする
          target_minutes_count = meet_event.count - 1

          # 議事録の取得処理
          begin
            minutes_accessor = Swimmy::Service::MinutesAccessor.new()
            target_minutes = minutes_accessor.create(target_minutes_count, type)
            if target_minutes.nil?
              raise "前回の議事録が見つかりません: count=#{target_minutes_count}, type=#{type}"
            end
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
