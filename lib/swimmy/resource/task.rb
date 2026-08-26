require "json"

module Swimmy
  module Resource
    class Task
      attr_reader :id, :content, :state, :description, :due_at, :created_at,
                  :updated_at, :creator, :assigner, :project, :url

      def initialize(id:, content:, created_at:, updated_at:, creator:, assigner:, url:,
                      state: nil, description: nil, due_at: nil, project: nil)
        @id = id
        @content = content
        @state = state
        @description = description
        @due_at = due_at
        @created_at = created_at
        @updated_at = updated_at
        @creator = creator
        @assigner = assigner
        @project = project
        @url = url
      end

      def self.from_hash(hash)
        new(
          id: hash["id"],
          content: hash["content"],
          state: hash["state"],
          description: hash["description"],
          due_at: hash["due_at"],
          created_at: hash["created_at"],
          updated_at: hash["updated_at"],
          creator: IdName.from_hash(hash["creator"]),
          assigner: IdName.from_hash(hash["assigner"]),
          project: IdName.from_hash(hash["project"]),
          url: hash["url"]
        )
      end

      def self.parse_list(json_string)
        JSON.parse(json_string).map { |hash| from_hash(hash) }
      end
    end
  end
end
