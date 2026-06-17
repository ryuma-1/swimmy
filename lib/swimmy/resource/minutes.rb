module Swimmy
  module Resource
    class Minutes
      TYPE_NEW = "new"
      TYPE_GN = "gn"

      def initialize(num, type, title, body, start_at, end_at, url)
        unless num.is_a?(Integer)
          raise ArgumentError, "Minutes number must be an integer"
        end
        unless title.is_a?(String)
          raise ArgumentError, "Minutes title must be a string"
        end
        unless body.is_a?(String)
          raise ArgumentError, "Minutes body must be a string"
        end
        unless [TYPE_NEW, TYPE_GN].include?(type)
          raise ArgumentError, "Minutes type must be either 'new' or 'gn'"
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
        
        @num = num
        @title = title
        @body = body
        @type = type
        @start_at = start_at
        @end_at = end_at
        @url = trim_url(url)
      end


      def self.title_to_num(title)
        if title.nil?
          raise ArgumentError, "Title cannot be nil"
        end
        unless title.is_a?(String)
          raise ArgumentError, "Title must be a string"
        end

        # 第-回の形式から数字を抽出する正規表現
        match = title.match(/第\s*(\d+)\s*回/)
        if match
          return match[1].to_i  # 抽出した数字を整数に変換して返す
        else
          raise ArgumentError, "第-回の形式ではありません: #{title}"
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
    end # class Minutes
  end # module Resource
end # module Swimmy