require 'json'

module Swimmy
  module Service
    class MinutesSelector
      def select(count, type)
        if count.nil?
          raise ArgumentError, "count cannot be nil"
        end
        if type.nil?
          raise ArgumentError, "type cannot be nil"
        end
        unless count.is_a?(Integer)
          raise ArgumentError, "count must be an Integer"
        end

        # raskからドキュメントを取得する
        minutes_docs = Swimmy::Service::Rask.document_list(content: [type.to_s, count.to_s], start_at: Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ'), term_duration: 30)

        if minutes_docs.nil?
          raise "rask_CLI returned nil output for count=#{count}, type=#{type}"
        end

        minutes_doc =  minutes_docs.first
        minutes = Swimmy::Resource::Minutes.new(
          Swimmy::Resource::Minutes.title_to_count(minutes_doc.content), # num
          minutes_doc.content,                          # title (contentをタイトルと仮定)
          minutes_doc.description || "",                # body (descriptionを本文と仮定)
          minutes_doc.start_at ? Time.parse(minutes_doc.start_at) : nil, # start_at
          minutes_doc.end_at ? Time.parse(minutes_doc.end_at) : nil,      # end_at
          minutes_doc.url || ""                         # url (urlをURLと仮定)
        )

        minutes
      end # access
    end # class MinutesSelector
  end # module Service
end # module Swimmy
