module Restrictable
  module Model
  extend ActiveSupport::Concern
    module ClassMethods

      def restricted_user_model
        @restricted_user_model ||= Restrictable.config["restricted_user_model"]
      end

      def restricted_user_model_class_name
        module_part = "#{restricted_user_model['engine']}::" unless restricted_user_model['engine'].blank?
        "#{module_part}#{restricted_user_model["class"]}"
      end

      def restricted_user_table_name
        restricted_user_model_class_name.underscore.gsub("/","_").pluralize
      end


      def all_from admin, through_class, object_class
        through_instance_name = through_class.name.demodulize.underscore
        through_id_name = "#{through_instance_name}_id".to_sym

        #
        # Rails Bug || Oddity:  [Admin belongs_to :group]
        #
        # Admin.method_defined? "group_id" => false
        # Admin.new.respond_to? "group_id" => true
        # Admin.method_defined? "group_id" => true
        #

        if object_class.new.respond_to? through_id_name
          from = object_class
        else
          through_index_name = through_instance_name.pluralize
          if object_class.new.respond_to? through_index_name
            from = object_class.joins(through_index_name.to_sym)
          end
        end

        if from 
          instance_ids = admin.send(through_instance_name).descendents(true).select(:id)
          from.where("#{through_id_name} in (#{instance_ids.pluck(:id).join(',')}) ")
        else
          raise ArgumentError, 'Restrictable Configuration Error[all_from]'
        end
      end

      #
      # Main Class Methods
      #

      def restricted_through through_method, object_class = nil
        @through_method = through_method
        @object_class = object_class
      end

      def for_admin admin 
        if admin.is_super?
          all
        elsif @through_method.nil?
          none
        elsif @through_method == :restricted_user
          joins(restricted_user_table_name.to_sym)
            .where("#{restricted_user_table_name}.id = ?",admin.restrictable_role_id)
        elsif @object_class
          all_from admin, @through_method, @object_class
        else
          send(@through_method,admin.face)
        end
      end
    end


    included do
      unless restricted_user_model.blank?
        has_many restricted_user_model["class"].underscore.pluralize.to_sym
      end
    end
  end
end
