require "json"

module Swimmy
  module Resource
    class Document
      attr_reader :id, :content, :creator, :description, :created_at, :updated_at,
                  :project, :start_at, :end_at, :location, :url

      def initialize(id:, content:, creator:, created_at:, updated_at:, url:,
                      description: nil, project: nil, start_at: nil, end_at: nil, location: nil)
        @id = id
        @content = content
        @creator = creator
        @description = description
        @created_at = created_at
        @updated_at = updated_at
        @project = project
        @start_at = start_at
        @end_at = end_at
        @location = location
        @url = url
      end

      def self.from_hash(hash)
        new(
          id: hash["id"],
          content: hash["content"],
          creator: IdName.from_hash(hash["creator"]),
          description: hash["description"],
          created_at: hash["created_at"],
          updated_at: hash["updated_at"],
          project: IdName.from_hash(hash["project"]),
          start_at: hash["start_at"],
          end_at: hash["end_at"],
          location: hash["location"],
          url: hash["url"]
        )
      end

      def self.parse_list(json_string)
        JSON.parse(json_string).map { |hash| from_hash(hash) }
      end
    end
  end
end
