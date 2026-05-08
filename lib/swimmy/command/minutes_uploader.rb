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

          # ハッシュ（辞書）をループして処理
          MINUTE_TYPES.each do |name, index|
            target_calendar = calendars[index]
            client.say(channel: data.channel, text: "Processing calendar: #{target_calendar.name} (ID: #{target_calendar.id})")

            # カレンダーが存在しない場合のガード
            next unless target_calendar

            date = Date.today

            if (!match[:expression].nil?) then
              date = Date.parse(match[:expression]) rescue nil
              if date.nil?
                client.say(channel: data.channel, text: "無効な日付形式です．正しい形式で入力してください．例: 2024-07-01")
                next
              end
            end

            cal_service = Swimmy::Service::CalendarGateway.new(target_calendar)
            events = cal_service.date_to_events(date)

            if events.empty?
              client.say(channel: data.channel, text: "【#{name}】#{date}のイベントはありません．")
            else
              current_event_num = nil
              events.each do |event|
                client.say(channel: data.channel, text: "【#{name}】Event: #{event.summary} at #{event.start}")
                current_event_num = Minutes.title_to_num(event.summary)
              end

              # 1. 実行ファイルのあるディレクトリを絶対パスで特定
              # __dir__ は、このRubyファイルが存在するディレクトリのフルパスを返します
              executable_path = File.expand_path("../../../bin/rask_CLI", __dir__)

              json = `#{executable_path} search-doc --content "#{name}" --start-at #{Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')} --term-day 60`

              File.open("log.txt", "a") do |f|
                f.puts "Raw JSON output: #{json}"
              end

              # 2. JSONをパース（キーをシンボルにする）
              raw_data = JSON.parse(json, symbolize_names: true)

              # 3. 配列の各要素を Minutes クラスに変換
              minutes_list = raw_data.map do |doc|
                Minutes.new(
                  Minutes.title_to_num(doc[:content]), # num
                  Minutes.string_to_type(name.to_s), # type
                  doc[:content],                          # title (contentをタイトルと仮定)
                  doc[:description] || "",                # body (descriptionを本文と仮定)
                  doc[:start_at] ? Time.parse(doc[:start_at]) : nil, # start_at
                  doc[:end_at] ? Time.parse(doc[:end_at]) : nil,      # end_at
                  doc[:url] || ""                         # url (urlをURLと仮定)
                )
              end

              client.say(channel: data.channel, text: "Found #{minutes_list.size} minutes for #{name}.")

              # current_event_num と比較して，1つ前の議事録を見つける
              second_largest_minutes = minutes_list.select { |m| m.num < current_event_num }.max_by(&:num)

              client.say(channel: data.channel, text: "前回の議事録の URL : #{second_largest_minutes.url}") if second_largest_minutes && second_largest_minutes.url
            end
          end
        rescue => e
          client.say(channel: data.channel, text: "エラーが発生しました: #{e.message}")
        end
      end

      class Minutes
        TYPE_NEW = "new"
        TYPE_GN = "gn"


        def initialize(num, type, title, body, start_at, end_at, url)
          @num = num
          @title = title
          @body = body
          @type = type
          @start_at = start_at
          @end_at = end_at
          @url = trim_url(url)
        end



        def self.title_to_num(title)
          # 第-回の形式から数字を抽出する正規表現
          match = title.match(/第\s*(\d+)\s*回/)
          if match
            return match[1].to_i  # 抽出した数字を整数に変換して返す
          else
            return nil  # タイトルに数字が含まれていない場合は nil を返す
          end
        end
      
        def self.string_to_type(name)
          if name.nil?
            raise ArgumentError, "Type name cannot be nil"
          end
          unless name.is_a?(String)
            raise ArgumentError, "Type name must be a string"
          end

          case name.downcase
          when 'new'
            TYPE_NEW
          when 'gn'
            TYPE_GN
          else
            raise ArgumentError, "Unknown type: #{name}"
          end
        end

        def num
          @num
        end

        def title
          @title
        end

        def body
          @body
        end

        def type
          @type
        end

        def start_at
          @start_at
        end

        def end_at
          @end_at
        end

        def url
          @url
        end

        private

        # URL から.jsonを取り除く関数
        def trim_url(url)
          return url.sub(/\.json$/, '')
        end
      end
    end
  end
end
