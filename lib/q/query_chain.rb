require_dependency "#{File.dirname(__FILE__)}/core.rb"
require 'binding_of_caller'

module Q
  class Core
    def self.query_chain(qlass = self, &block)
      chain = QueryChain.new(qlass)
      chain.instance_exec &block if block_given?
      chain._result
    end

    delegate :query_chain, to: :class
  end

  class QueryChain
    @relation
    @self

    def initialize(qlass)
      @relation = qlass.all
      @self = binding.of_caller(0).receiver
    end

    def method_missing(name, *args, &block)
      if @relation.respond_to? name
        @relation = @relation.send(name, *args, &block)
      elsif @self.respond_to? name
        @self.send(name, *args, &block)
      else
        super
      end
    end

    def select(*args, &block)
      method_missing(:select, *args, &block)
    end

    def _result
      @relation
    end
  end
end
