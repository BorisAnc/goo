require_relative "settings/settings"

module Goo
  module Base

    class Resource
      include Goo::Base::Settings
      #include Goo::Search

      attr_reader :loaded_attributes
      attr_reader :modified_attributes
      attr_reader :errors

      attr_accessor :id

      def initialize(*args)
        options = args[0] || {}
        attributes = options[:attributes]
        @loaded_attributes = Set.new
        @modified_attributes = Set.new
        @persistent = false || options[:persistent]
      end

      def valid?
        validation_errors = {}
        self.class.attributes.each do |attr|
          inst_value = self.instance_variable_get("@#{attr}")
          attr_errors = Goo::Validators::Enforce.enforce(self,attr,inst_value)
          unless attr_errors.nil?
            validation_errors[attr] = attr_errors
          end
        end
        @errors = validation_errors.freeze
        return @errors.length == 0
      end
    end

  end
end
