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

        MINUTE_TYPES.each do |name, index|
          # 2. 予定の取得処理
          begin
            # spreadsheet オブジェクトの取得
            sheet = spreadsheet.sheet("calendar", Swimmy::Resource::Calendar)
            calendars = sheet.fetch

            target_calendar = calendars[index]
            client.say(channel: data.channel, text: "Processing calendar: #{target_calendar.name} (ID: #{target_calendar.id})")

            if target_calendar.nil?
              raise "カレンダーが見つかりません: #{name} (インデックス: #{index})"
            end

            cal_service = Swimmy::Service::CalendarGateway.new(target_calendar)
            events = cal_service.date_to_events(Date.today)
          rescue => e
            client.say(channel: data.channel, text: "予定の取得に失敗しました: #{e.message}")
            next
          end

          # 予定がない場合はその旨を伝えて終了
          if events.empty?
            client.say(channel: data.channel, text: "【#{name}】#{Date.today}のイベントはありません．")
            next
          end

          # 3. イベントの出力と議事録の回数の特定
          current_event_num = nil
          begin
            events.each do |event|
              client.say(channel: data.channel, text: "【#{name}】Event: #{event.summary} at #{event.start}")
              current_event_num = Minutes.title_to_num(event.summary)
            end
          rescue => e
            client.say(channel: data.channel, text: "イベントの処理に失敗しました: #{e.message}")
            next
          end

          # 4. rask_CLI を実行して資料の情報を取得
          begin 
            # 実行ファイルのあるディレクトリを絶対パスで特定
            executable_path = File.expand_path("../../../bin/rask_CLI", __dir__)
            json = `#{executable_path} search-doc --content "#{name}" --start-at #{Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')} --term-day 30`
          rescue => e
            client.say(channel: data.channel, text: "rask_CLIの実行に失敗しました: #{e.message}")
            next
          end

          # 5. JSONのパースと議事録の特定
          begin        
            # JSONをパース（キーをシンボルにする）
            raw_data = JSON.parse(json, symbolize_names: true)

            # 配列の各要素を Minutes クラスに変換
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
            # current_event_num と比較して，1つ前の議事録を見つける
            second_largest_minutes = minutes_list.select { |m| m.num < current_event_num }.max_by(&:num)
          rescue => e
            client.say(channel: data.channel, text: "議事録の作成に失敗しました: #{e.message}")
            next
          end
          
          # 6. Slackへの出力
          client.say(channel: data.channel, text: "前回の議事録 : #{second_largest_minutes.url}") if second_largest_minutes && second_largest_minutes.url
          client.say(channel: data.channel, text: "議事録作成 https://rask.nomlab.org/documents/new")
          
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
