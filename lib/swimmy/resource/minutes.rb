module Swimmy
  module Resource
    class Minutes
      MIN_COUNT = 1
      TITLE = "検討打合せ".freeze
      COUNT_REGEX = /第\s*(\d+)\s*回/.freeze
      TYPE = {
        GN: 1,
        New: 2
      }.freeze

      def initialize(count, title, body, start_at, end_at, url)
        if count.nil?
          raise ArgumentError, "count cannot be nil"
        end
        if title.nil?
          raise ArgumentError, "title cannot be nil"
        end
        if body.nil?
          raise ArgumentError, "body cannot be nil"
        end
        if start_at.nil?
          raise ArgumentError, "start_at cannot be nil"
        end
        if end_at.nil?
          raise ArgumentError, "end_at cannot be nil"
        end
        if url.nil?
          raise ArgumentError, "url cannot be nil"
        end

        unless count.is_a?(Integer)
          raise ArgumentError, "Minutes count must be an integer"
        end
        unless title.is_a?(String)
          raise ArgumentError, "Minutes title must be a string"
        end
        unless body.is_a?(String)
          raise ArgumentError, "Minutes body must be a string"
        end
        unless start_at.is_a?(Time) || start_at.nil?
          raise ArgumentError, "Minutes start_at must be a Time object or nil"
        end
        unless end_at.is_a?(Time) || end_at.nil?
          raise ArgumentError, "Minutes end_at must be a Time object or nil"
        end
        unless url.is_a?(String)
          raise ArgumentError, "Minutes url must be a string"
        end

        unless count >= MIN_COUNT
          raise ArgumentError, "Minutes count must be greater than or equal to #{MIN_COUNT}"
        end

        unless self.class.is_valid_content(title)
          raise ArgumentError, "Invalid content format: #{title}"
        end

        @count = count
        @type = self.class.title_to_type(title)
        @title = title
        @body = body
        @start_at = start_at
        @end_at = end_at
        @url = trim_url(url)

        freeze
      end

      def count
        @count
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

      # 議事録のタイトルが有効な形式かどうかを判定するメソッド
      def self.is_valid_content(content)
        # 「検討打合せ」という文字列を含むかどうかを判定する
         content.include?(TITLE)
      end

      def self.title_to_count(title)
        if title.nil?
          raise ArgumentError, "Title cannot be nil"
        end
        unless title.is_a?(String)
          raise ArgumentError, "Title must be a string"
        end

        # 第-回の形式から数字を抽出する正規表現
        match = title.match(COUNT_REGEX)
        if match
          return match[1].to_i  # 抽出した数字を整数に変換して返す
        else
          raise ArgumentError, "第-回の形式ではありません: #{title}"
        end
      end

      def self.title_to_type(title)
        if title.nil?
          raise ArgumentError, "Type title cannot be nil"
        end
        unless title.is_a?(String)
          raise ArgumentError, "Type title must be a string"
        end

        normalized_title = title.unicode_normalize(:nfkc)

        matched_key = TYPE.keys.find { |key| normalized_title.include?(key.to_s) }
        raise ArgumentError, "Unknown type: #{title}" unless matched_key

        TYPE[matched_key]
      end


      # URL から.jsonを取り除く関数
      def trim_url(url)
        return url.sub(/\.json$/, '')
      end
    end # class Minutes

    class MinutesCollection
      include Enumerable

      # @param minutes_list [Array<Minutes>] Minutesオブジェクトの配列
      def initialize(minutes_list)
        unless minutes_list.is_a?(Array)
          raise ArgumentError, "minutes_list must be an Array"
        end
        unless minutes_list.all? { |m| m.is_a?(Minutes) }
          raise ArgumentError, "minutes_list must contain only Minutes objects"
        end

        # 外部からの破壊的変更を防ぐため複製してfreeze
        @minutes_list = minutes_list.dup.freeze
      end

      # Enumerableを使えるようにするための必須実装
      # これにより map / select / sort_by / find などが自動的に使えるようになる
      def each
        return enum_for(:each) unless block_given?

        @minutes_list.each { |minutes| yield(minutes) }
        self
      end

      def to_a
        @minutes_list.dup
      end

      def size
        @minutes_list.size
      end
      alias length size

      def empty?
        @minutes_list.empty?
      end

      # 回数（count）の完全一致検索
      def find_by_count(count)
        new_collection { |m| m.count == count }
      end

      # タイトルの部分一致検索
      def find_by_title(keyword)
        new_collection { |m| m.title.include?(keyword) }
      end

      # 本文の部分一致検索
      def find_by_body(keyword)
        new_collection { |m| m.body.include?(keyword) }
      end

      # 種別（TYPE_NEW / TYPE_GN）の完全一致検索
      def find_by_type(type)
        new_collection { |m| m.type == type }
      end

      # URLの完全一致検索
      def find_by_url(url)
        new_collection { |m| m.url == url }
      end

      # 開始時刻が指定範囲内のものを検索（nilは除外）
      def find_by_start_at_between(from, to)
        new_collection do |m|
          !m.start_at.nil? && m.start_at >= from && m.start_at <= to
        end
      end

      # 終了時刻が指定範囲内のものを検索（nilは除外）
      def find_by_end_at_between(from, to)
        new_collection do |m|
          !m.end_at.nil? && m.end_at >= from && m.end_at <= to
        end
      end

      # 任意の条件で絞り込みたい場合の汎用メソッド
      # 呼び出し側にブロックを渡してもらう形
      def find_by(&block)
        new_collection(&block)
      end

      # ---- ソート系（こちらも新しいコレクションを返す） ----

      # countの昇順に並べたコレクションを返す
      def sort_by_count
        self.class.new(@minutes_list.sort_by(&:count))
      end

      # start_atの昇順に並べたコレクションを返す（nilは末尾）
      def sort_by_start_at
        sorted = @minutes_list.sort_by do |m|
          [m.start_at.nil? ? 1 : 0, m.start_at || Time.at(0)]
        end
        self.class.new(sorted)
      end

      private

      # 条件に合うMinutesだけを抽出して新しいMinutesCollectionを生成する内部ヘルパー
      def new_collection(&block)
        self.class.new(@minutes_list.select(&block))
      end
    end
  end # module Resource
end # module Swimmy
