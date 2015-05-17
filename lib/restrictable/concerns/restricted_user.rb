module Restrictable
  module RestrictedUser
  extend ActiveSupport::Concern
    attr_accessor :facade, :facade_id

    #
    # class methods
    #

    module ClassMethods
      def supers
        where(role: 'super')
      end
      
      def admins
        where(role: 'admin')
      end

      def admins_for_group group
        admins.where(group: group)
      end
    end

    #
    # included
    #

    included do
      validates_presence_of :role
      unless restrictable_models.blank?
        restrictable_models.each do |restrictable_model|
          belongs_to restrictable_model["class"].underscore.to_sym, class_name: restrictable_model_to_class_name(restrictable_model)
        end
      end
    end

    #
    # instance methoods
    #


    def hard_super?
      @hard_super ||= (role == 'super')
    end

    def restrictable_role
      if !facade.blank? && hard_super?
        facade
      else
        @restrictable_role ||= role
      end      
    end

    def restrictable_role_id
      if !facade_id.blank? && hard_super?
        facade_id
      else
        @restrictable_role_id ||= id
      end      
    end

    def restrictable_user
      if !!facade_id
        self.find_by(id: facade_id)
      else
        self
      end
    end 

    def is_super?
      @is_super ||= (restrictable_role == 'super')
    end

    def is_admin?
      @is_admin ||= (restrictable_role == 'admin')
    end

    def can? action
      is_super? || unless (permissions.blank? || permissions[restrictable_role].blank?)
        permissions[restrictable_role].include? action.to_s
      end
    end
  
  # private

    module ClassMethods

      def roles
        [ 'super', 'admins' ] | custom_roles
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
            restrictable_model = restrictable_model_find_by_class_name parts[1]
            if restrictable_model
              {
                roles: parts[0],
                object: parts[1]
              }
            end
          end
        end
      end

      def method_missing(method_call, *arguments, &block)
        hash = method_hash(method_call)
        if hash.nil?
          super
        else
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

      def restrictable_models
        @restrictable_models ||= Restrictable.config["restrictable_models"]
      end

      def restrictable_model_to_class_name restrictable_model
        module_part = "#{restrictable_model['engine']}::" unless restrictable_model['engine'].blank?
        "#{module_part}#{restrictable_model["class"]}"
      end

      def restrictable_model_find_by_class_name class_name
        restrictable_models.select{|restrictable_model| restrictable_model["class"].underscore == class_name }.first
      end

    end

    #
    # Dynamic Methods
    #

    def permissions
      @permissions ||= Restrictable.config["permissions"]
    end

    def role_check dynamic_role
      restrictable_role == dynamic_role
    end

    def role_check_role method_name
      if method_name.starts_with?("is_") && method_name.ends_with?("?")
        role_check_class_name = method_name.gsub(/^is_/,'').gsub(/\?$/,"")
        if custom_roles.include?(role_check_class_name)
          role_check_class_name
        end
      end
    end

    def objects dynamic_hash
      if is_super?
        self.class.restrictable_model_to_class_name(dynamic_hash).constantize.all
      else
        dynamic_role = dynamic_hash["class"].underscore
        top_obj = send(dynamic_role)
        unless top_obj.nil?
          top_obj.descendents(true)
        end
      end
    end

    def objects_hash method_name
      if method_name.pluralize == method_name
        self.class.restrictable_model_find_by_class_name method_name.singularize
      end
    end

    def method_missing(method_call, *arguments, &block)
      hash = method_hash(method_call)
      if hash.nil?
        super
      else
        send(hash[:method],hash[:param],*arguments)
      end
    end

    def method_hash(method_call)
      method_name = method_call.to_s
      method_role_name = role_check_role(method_name)
      if method_role_name
        { 
          method: 'role_check',
          param: method_role_name
        }
      else
        method_objects_dict = objects_hash(method_name)
        if method_objects_dict
          { 
            method: 'objects',
            param: method_objects_dict
          }
        end
      end    
    end

    def respond_to_missing?(method_call, include_private = false)
      !method_hash(method_call).nil? || super
    end

    def custom_roles
      self.class.custom_roles
    end

    def restrictable_models
      self.class.restrictable_models
    end

  end
end
