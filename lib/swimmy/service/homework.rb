module Swimmy
  module Service
    class Homework
      DESC_GT_ENTITY = /\\u003e/
      HOMEWORK_TASK_PATTERN = /--\s*>\s*\(([^!]+) !:(\d+)\)/

      def self.driver
        Swimmy::Service::RaskCliDriver
      end

      # タイトルからホームワークを取得
      def self.get_homeworks_by_title(title)
        documents = driver.document_list(content: [title])
        extract_homeworks(documents)
      end

      # Document一覧からホームワーク情報を抽出
      def self.extract_homeworks(documents)
        homeworks = []

        documents.each do |doc|
          desc = doc.description
          next unless desc

          # \\u003eを>に変換
          desc = desc.gsub(DESC_GT_ENTITY, ">")

          desc.scan(HOMEWORK_TASK_PATTERN).each do |name, ai_num|
            homework = Swimmy::Resource::Homework.new(
              name: name.strip,
              ai_number: ai_num.strip,
              doc_id: doc.id.to_s,
              task_url: nil
            )
            homeworks << homework
          end
        end

        homeworks
      end

      # インスタンス経由の呼び出しを許容
      def get_homeworks_by_title(title)
        self.class.get_homeworks_by_title(title)
      end
    end
  end
end
