require_dependency "#{File.dirname(__FILE__)}/core.rb"

module Q
  class Core
    delegate :table, to: :class

    def self.table
      TableMock.new(table_name)
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
end
