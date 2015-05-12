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

      #
      # Main Class Methods
      #

      def restricted_through through_method
        @through_method = through_method
      end

      def for_admin current_admin 
        if current_admin.is_super?
          all
        elsif @through_method.nil?
          none
        elsif @through_method == :restricted_user
          joins(restricted_user_table_name.to_sym).where("#{restricted_user_table_name}.id = ?",current_admin.id)
        else
          send(@through_method,current_admin)
        end
      end
    end


    included do
      unless restricted_user_model.blank?
        has_many restricted_user_model["class"].underscore.pluralize.to_sym
      end
    end

    def test
      "# move logic here"
    end
  end
end
