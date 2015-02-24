module Restrictable
  module Model
  extend ActiveSupport::Concern

    module ClassMethods
      def for_admin current_admin
        if current_admin.is_super?
          all
        else
          joins(:admins).where('admins.id = ?',current_admin.id)
        end
      end
    end

    def test
      "# move logic here"
    end
  end
end
