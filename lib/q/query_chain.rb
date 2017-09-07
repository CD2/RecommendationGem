require_dependency "#{File.dirname(__FILE__)}/core.rb"

module Q
  class ApplicationRecord
    delegate :table, :query_chain, to: :class

    def self.table
      TableMock.new(table_name)
    end

    def self.query_chain(qlass = self, &block)
      chain = QueryChain.new(qlass)
      chain.instance_exec &block if block_given?
      chain._result
    end

    def self.method_missing(name, *args, &block)
      return table.send(name) if column_names.include? name.to_s
      super
    end
  end

  class TableMock
    @string

    def initialize(string)
      @string = string
    end

    def method_missing(name, *args, &block)
      Q.quote(@string, name)
    end

    def to_s
      Q.quote(@string)
    end
  end

  class QueryChain
    @relation

    def initialize(qlass)
      @relation = qlass.all
    end

    def method_missing(name, *args, &block)
      @relation = @relation.send(name, *args, &block)
    end

    def select(*args, &block)
      method_missing(:select, *args, &block)
    end

    def inner_join(model, opts = {})
      join(model, 'INNER JOIN', opts)
    end

    def left_join(model, opts = {})
      join(model, 'LEFT JOIN', opts)
    end

    def _result
      @relation
    end

    private

    def join(model, join_type, opts)
      options = opts.with_indifferent_access
      target = "(#{model.to_sql})" if model.respond_to? :to_sql
      target ||= model.table_name if model.respond_to? :table_name
      target ||= model.to_s
      target_name = target
      as = ''
      if options[:as]
        as = " AS #{options[:as]}"
        target_name = options[:as]
      end
      on = 'TRUE'
      if options[:on]
        on = options[:on].map { |x|
          if x.is_a? Array
            "#{Q.quote(table_name, x[0])} = #{Q.quote(target_name, x[1])}"
          else
            x.to_s
          end
        }.join(' AND ')
      end
      @relation = @relation.joins("#{join_type} #{target}#{as} ON #{on}")
    end
  end
end
