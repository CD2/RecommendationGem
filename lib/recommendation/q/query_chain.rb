# frozen_string_literal: true

require_dependency "#{File.dirname(__FILE__)}/core.rb"
require 'binding_of_caller'

module Recommendation
  module Q
    class Core
      def self.query_chain(qlass = self, &block)
        chain = QueryChain.new(qlass)
        chain.instance_exec &block if block_given?
        chain._result
      end

      # Replacing this with a delegation causes binding issues
      def query_chain(qlass = self, &block)
        chain = QueryChain.new(qlass)
        chain.instance_exec &block if block_given?
        chain._result
      end
    end

    class QueryChain
      # New classes get some methods by default
      # This forces a method_missing while retaining their super
      %i[select as_json].each do |name|
        define_method name do |*args, &block|
          method_missing name, *args, &block
        end
      end

      def initialize(relation)
        @relation = relation.all
        @self = binding.of_caller(1).receiver
      end

      # Got a method that exists on both @relation and @self?
      # Manually call @self.your_method or @relation.your_method in the block
      def method_missing(name, *args, &block)
        if @relation.respond_to? name
          @relation = @relation.send(name, *args, &block)
        elsif @self.respond_to? name
          @self.send(name, *args, &block)
        else
          super
        end
      end

      def local
        yield if block_given?
      end

      def _result
        @relation
      end
    end
  end
end
