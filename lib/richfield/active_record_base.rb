require 'richfield/compatibility'

module Richfield
  module ActiveRecordBase
    extend ActiveSupport::Concern

    module ClassMethods
      attr_reader :richfield_fields
      attr_reader :richfield_table_options

      # creates the field definitons if they haven't been created yet
      def richfield_fields_create
        @richfield_fields ||= Richfield::Compatibility.create_table_definition(connection, table_name)
      end

      def fields options={}
        cols = richfield_fields_create
        @richfield_table_options ||= {}
        @richfield_table_options.merge!(options)
        yield cols if block_given?
      end
    end
  end
end

ActiveRecord::Base.send :include, Richfield::ActiveRecordBase
