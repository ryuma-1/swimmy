require 'json'

module Swimmy
  module Service
    class MinutesAccessor
      def create(count, type)
        if count.nil?
          raise ArgumentError, "count cannot be nil"
        end
        if type.nil?
          raise ArgumentError, "type cannot be nil"
        end
        unless count.is_a?(Integer)
          raise ArgumentError, "count must be an Integer"
        end
        unless Swimmy::Resource::Minutes::TYPE.key?(type)
          raise ArgumentError, "type must be one of #{Swimmy::Resource::Minutes::TYPE.keys.join(', ')}"
        end

        # rask_CLI を実行して資料の情報を取得
        # 実行ファイルのあるディレクトリを相対パスで特定
        executable_path = File.expand_path("../../../bin/rask_CLI", __dir__)
        json = `#{executable_path} search-doc --content "#{type.to_s}" --content "#{count}" --start-at #{Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')} --term-day 30 --is-json`

        if json.nil?
          raise "rask_CLI returned nil output for count=#{count}, type=#{type}"
        end

        if json.empty?
          raise "rask_CLI returned empty output for count=#{count}, type=#{type}"
        end

        # JSONのパースと議事録の特定
        # JSONをパース（キーをシンボルにする）
        raw_data = JSON.parse(json, symbolize_names: true)

        if raw_data.count == 0 || raw_data.nil?
          raise "JSON の解析に失敗しました: count=#{count}, type=#{type}"
        end

        if raw_data.count > 1
          raise "複数の議事録が見つかりました: count=#{count}, type=#{type}, found_count=#{raw_data.count}"
        end

        minutes_date =  raw_data.first
        minutes = Swimmy::Resource::Minutes.new(
          Swimmy::Resource::Minutes.title_to_count(minutes_date[:content]), # num
          minutes_date[:content],                          # title (contentをタイトルと仮定)
          minutes_date[:description] || "",                # body (descriptionを本文と仮定)
          minutes_date[:start_at] ? Time.parse(minutes_date[:start_at]) : nil, # start_at
          minutes_date[:end_at] ? Time.parse(minutes_date[:end_at]) : nil,      # end_at
          minutes_date[:url] || ""                         # url (urlをURLと仮定)
        )

        minutes
      end # create
    end # class MinutesFactory
  end # module Service
end # module Swimmy
