require "json"

module Swimmy
  module Resource
    class Project
      attr_reader :id, :name, :created_at, :updated_at, :user, :url

      def initialize(id:, name:, created_at:, updated_at:, user:, url:)
        @id = id
        @name = name
        @created_at = created_at
        @updated_at = updated_at
        @user = user
        @url = url
      end

      def self.from_hash(hash)
        new(
          id: hash["id"],
          name: hash["name"],
          created_at: hash["created_at"],
          updated_at: hash["updated_at"],
          user: IdName.from_hash(hash["user"]),
          url: hash["url"]
        )
      end

      def self.parse_list(json_string)
        JSON.parse(json_string).map { |hash| from_hash(hash) }
      end
    end
  end
end
