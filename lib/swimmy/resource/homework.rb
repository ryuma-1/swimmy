module Swimmy
  module Resource
    class Homework
      attr_reader :name, :ai_number, :doc_id, :task_url

      def initialize(name:, ai_number:, doc_id:, task_url:, rask_url: nil)
        @name = name
        @ai_number = ai_number
        @doc_id = doc_id
        @task_url = task_url || build_default_task_url(rask_url, doc_id, ai_number)
        @rask_url = rask_url
      end

      # Slack形式のリンク表記
      def to_slack_link
        "<#{@task_url}|#{@name}{#{@ai_number}}>"
      end

      private

      def build_default_task_url(rask_url, doc_id, ai_number)
        base_url = rask_url || "https://rask.nomlab.org"
        "#{base_url}/tasks/new?desc_header=Created+from+[AI#{ai_number}](#{base_url}/documents/#{doc_id}?ai=#{ai_number})"
      end
    end
  end
end
