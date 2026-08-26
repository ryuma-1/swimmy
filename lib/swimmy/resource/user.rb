require "json"

module Swimmy
  module Resource
    class User
      attr_reader :id, :name, :screen_name, :active, :created_at, :updated_at, :url

      def initialize(id:, name:, screen_name:, active:, created_at:, updated_at:, url:)
        @id = id
        @name = name
        @screen_name = screen_name
        @active = active
        @created_at = created_at
        @updated_at = updated_at
        @url = url
      end

      def self.from_hash(hash)
        new(
          id: hash["id"],
          name: hash["name"],
          screen_name: hash["screen_name"],
          active: hash["active"],
          created_at: hash["created_at"],
          updated_at: hash["updated_at"],
          url: hash["url"]
        )
      end

      def self.parse_list(json_string)
        JSON.parse(json_string).map { |hash| from_hash(hash) }
      end
    end
  end
end
