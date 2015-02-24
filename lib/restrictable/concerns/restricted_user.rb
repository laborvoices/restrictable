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
        where(role: 'super')
      end
      
      def admins
        where(role: 'admin')
      end

      def admins_for_group group
        admins.where(group: group)
      end

      #
      # Dynamic Class Methods
      #

      def objects dynamic_role, args
        where(role: dynamic_role)
      end

      def objects_role method_name
        if custom_roles.include?(method_name.singularize)
          method_name
        end
      end

      def roles_for dynamic_hash, arguments
        object = arguments[0]
        send(dynamic_hash[:roles]).where("admins.#{dynamic_hash[:object]}_id = ?" ,object.id)
      end

      def roles_for_hash method_name
        parts = method_name.split("_for_")
        if parts.length == 2
          if custom_roles.include?(parts[0].singularize)
            ru_rm_arr = restricted_user_restrictable_models.select{|ru_rm| ru_rm["class"].underscore == parts[1] }
            if ru_rm_arr.length > 0
              {
                roles: parts[0],
                object: parts[1]
              }
            end
          end
        end
      end

      def method_missing(method_call,*arguments)
        hash = method_hash(method_call)
        puts "mm2 -- #{hash}"
        if hash.nil?
          super
        else
        puts "send -- #{hash[:method]},#{hash[:param]},#{arguments}"
          send(hash[:method],hash[:param],arguments)
        end
      end

      def method_hash(method_call)
        method_name = method_call.to_s
        method_role_name = objects_role(method_name)
        if method_role_name
          { 
            method: 'objects',
            param: method_role_name
          }
        else
          roles_for_dict = roles_for_hash(method_name)
          if roles_for_dict
            { 
              method: 'roles_for',
              param: roles_for_dict
            }
          end
        end
      end

      def respond_to_missing?(method_call, include_private = false)
        !method_hash(method_call).nil? || super
      end

      def custom_roles
        @custom_roles ||= Restrictable.config["custom_roles"]
      end

      def restricted_user_restrictable_models
        @restricted_user_restrictable_models ||= Restrictable.config["restricted_user_restrictable_models"]
      end

      def ru_rm_to_class_name ru_rm
        module_part = "#{ru_rm['engine']}::" unless ru_rm['engine'].blank?
        "#{module_part}#{ru_rm["class"]}"
      end

    end

    #
    # included
    #

    included do
      validates_presence_of :role
      unless restricted_user_restrictable_models.blank?
        restricted_user_restrictable_models.each do |ru_rm|
          belongs_to ru_rm["class"].to_sym, class_name: ru_rm_to_class_name(ru_rm)
        end
      end
    end

    #
    # instance methoods
    #

    def groups 
      unless group.nil?
        if is_super?
          Group.all
        else
          group.descendents(true)
        end
      end
    end

    def is_super?
        @is_super ||= (role == 'super')
    end

    def is_admin?
      @is_admin ||= (role == 'admin')
    end

  # private

    #
    # Dynamic Methods
    #

    # def role_check dynamic_role, args
    #   role == dynamic_role
    # end

    # def role_check_role method_name
    #   if method_name.starts_with?("is_") && method_name.ends_with?("?")
    #     role_check_class_name = method_name.gsub(/^is_/,'').gsub(/\?$/,"")
    #     if custom_roles.include?(role_check_class_name.pluralize)
    #       role_check_class_name
    #     end
    #   end
    # end

    # def objects dynamic_role, args
    #   where(role: dynamic_role)
    # end

    # def objects_role method_name
    #   if custom_roles.include?(method_name)
    #     method_name
    #   end
    # end

    # def roles_for dynamic_hash, object
    #   send(dynamic_hash[:roles]).where(dynamic_hash[:object].to_sym => object)
    # end

    # def roles_for_hash method_name
    #   parts = method_name.split("_for_")
    #   if parts.length == 2
    #     if custom_roles.include?(parts[0])
    #       ru_rm_arr = restricted_user_restrictable_models.select{|ru_rm| ru_rm["class"].underscore == parts[1] }
    #       if ru_rm.length > 0
    #         {
    #           roles: parts[0],
    #           object: parts[1]
    #         }
    #       end
    #     end
    #   end
    # end

    def method_missing(method_call,*arguments)
      puts "mm i #{arguments}"
      puts "mm i #{arguments}"
      puts "mm i #{arguments}"
      puts "mm i #{arguments}"
      puts "mm i #{arguments}"

      send("id")
      # hash = method_hash(method_call)
      # if hash.nil?
      #   super
      # else
      #   send(hash[:method],hash[:param],*arguments)
      # end
    end

    # def method_hash(method_call)
    #   method_name = method_call.to_s
    #   method_role_name = role_check_role(method_name)
    #   if method_role_name
    #     { 
    #       method: 'role_check',
    #       param: method_role_name
    #     }
    #   else
    #     method_role_name = objects_role(method_name)
    #     if method_role_name
    #       { 
    #         method: 'objects',
    #         param: method_role_name
    #       }
    #     else
    #       roles_for_dict = roles_for_hash(method_name)
    #       if method_role_name
    #         { 
    #           method: 'roles_for',
    #           param: roles_for_dict
    #         }
    #       end
    #     end
    #   end    
    # end

    def respond_to_missing?(method_call, include_private = false)
      !method_hash(method_call).nil? || super
    end

    def custom_roles
      self.class.custom_roles
    end

    def restricted_user_restrictable_models
      self.class.restricted_user_restrictable_models
    end
  end
end
