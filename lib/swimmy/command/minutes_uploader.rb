require 'dotenv'
require 'json'

Dotenv.load

module Swimmy
  module Command
    class MinutesUploader < Swimmy::Command::Base
      MINUTE_TYPES = {
        GN:  1,
        New: 2 
      }.freeze

      command "minutes_uploader" do |client, data, match|
        MINUTE_TYPES.each do |name, index|
          # イベントの取得処理
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
          
          # 検討打合せのイベントがない場合はその旨を伝えて終了
          if meet_event.nil?
            client.say(channel: data.channel, text: "【#{name}】#{Date.today}のイベントに検討打合せはありません．")
            next
          end
          
          # イベントの出力と議事録の回数の特定
          current_event_num = nil
          begin
            current_event_num = Swimmy::Resource::Minutes.title_to_num(meet_event.name)
            client.say(channel: data.channel, text: "【#{name}】#{meet_event.name} #{meet_event.date}")

          rescue => e
            client.say(channel: data.channel, text: "議事録の処理に失敗しました: #{e.message}")
            next
          end

          # rask_CLI を実行して資料の情報を取得
          begin 
            # 実行ファイルのあるディレクトリを相対パスで特定
            executable_path = File.expand_path("../../../bin/rask_CLI", __dir__)
            json = `#{executable_path} search-doc --content "#{name}" --start-at #{Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')} --term-day 30 --is-json`
          rescue => e
            client.say(channel: data.channel, text: "rask_CLIの実行に失敗しました: #{e.message}")
            next
          end

          # JSONのパースと議事録の特定
          begin        
            # JSONをパース（キーをシンボルにする）
            raw_data = JSON.parse(json, symbolize_names: true)
            
            # 配列の各要素を Minutes オブジェクトに変換
            minutes_list = raw_data.map do |doc|
              Swimmy::Resource::Minutes.new(
                Swimmy::Resource::Minutes.title_to_num(doc[:content]), # num
                Swimmy::Resource::Minutes.string_to_type(name.to_s), # type
                doc[:content],                          # title (contentをタイトルと仮定)
                doc[:description] || "",                # body (descriptionを本文と仮定)
                doc[:start_at] ? Time.parse(doc[:start_at]) : nil, # start_at
                doc[:end_at] ? Time.parse(doc[:end_at]) : nil,      # end_at
                doc[:url] || ""                         # url (urlをURLと仮定)
              )
            end
 
            # current_event_num と比較して，1つ前の議事録を見つける
            previous_minute = minutes_list.select { |m| m.num < current_event_num }.max_by(&:num)

            if previous_minute.nil?
              raise "前回の議事録が見つかりません: current_event_num=#{current_event_num}"
            end
          rescue => e
            client.say(channel: data.channel, text: "議事録オブジェクトの処理に失敗しました: #{e.message}")
            next
          end

          # Slackへの出力
          client.say(channel: data.channel, text: "前回の議事録: #{previous_minute.url}")
          client.say(channel: data.channel, text: "議事録作成: https://rask.nomlab.org/documents/new")
        end
      end
    end
  end
end
