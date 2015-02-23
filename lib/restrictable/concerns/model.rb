module Restrictable
  module Model
  extend ActiveSupport::Concern

    module ClassMethods
      def for_admin
        all
      end
    end

    def test
      "# move logic here"
    end
  end
end
