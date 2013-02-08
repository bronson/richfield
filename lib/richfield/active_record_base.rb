module Richfield
  module ActiveRecordBase
    extend ActiveSupport::Concern

    module ClassMethods
      attr_reader :richfield_table_options

      def richfield_definition vivify=true
        @richfield_definiton ||= (vivify ? ActiveRecord::ConnectionAdapters::TableDefinition.new(connection) : nil)
      end

      def fields options={}
        cols = richfield_definition
        @richfield_table_options = options
        yield cols if block_given?
      end
    end
  end
end

ActiveRecord::Base.send :include, Richfield::ActiveRecordBase
