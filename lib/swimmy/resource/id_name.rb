module Swimmy
  module Resource
    # A small { id, name } reference, used for rask's creator/assigner/project fields.
    class IdName
      attr_reader :id, :name

      def initialize(id:, name:)
        @id = id
        @name = name
      end

      def self.from_hash(hash)
        return nil if hash.nil?

        new(id: hash["id"], name: hash["name"])
      end
    end
  end
end
