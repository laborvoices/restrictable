module Restrictable
  module RestrictedUser
  extend ActiveSupport::Concern

    #
    # class methods
    #

    module ClassMethods

      def roles
        [ 
          'super',
          'admins',
          'client',
          'translator'
        ]
      end
      
      def supers
        Admin.where(role: 'super')
      end
      
      def admins
        Admin.where(role: 'admin')
      end

      def clients
        Admin.where(role: 'client')
      end
      
      def translators
        Admin.where(role: 'translator')
      end

      def admins_for_group group
        admins.where(group: group)
      end

      def clients_for_group group
        clients.where(group: group)
      end

      def translators_for_group group
        clients.where(group: group)
      end
    
    end

    #
    # included
    #

    included do
      validates_presence_of :role
      belongs_to :group, class_name: "SurveyLink::Group"
    end

    #
    # instance methoods
    #

    def is_super?
        @is_super ||= (role == 'super')
    end

    def is_admin?
      @is_admin ||= (role == 'admin')
    end

    def is_client?
      @is_client ||= (role == 'client')
    end

    def is_translator?
      @is_translator ||= (role == 'translator')
    end

  end
end
