# frozen_string_literal: true

module Q
  def self.quote(*args)
    args.join('.').delete('"').split('.').map do |x|
      x.to_s == '*' ? '*' : "\"#{x}\""
    end.join('.')
  end

  def self.bracket(str)
    string = str.to_s
    return "(#{string})" if string[0] != '('
    sub_str = string.match(/(?<=\().*/).to_s
    depth = 1
    for i in 0...sub_str.size
      return "(#{string})" if depth == 0
      if sub_str[i] == '('
        depth += 1
      elsif sub_str[i] == ')'
        depth -= 1
      end
    end
    raise SyntaxError, 'Unmatched parentheses' unless depth == 0
    return string
  end

  class Core < ::ActiveRecord::Base
    self.abstract_class = true

    delegate :sql_execute, :sql_calculate, to: :class

    def self.sql_execute(command)
      connection.execute(command).to_a
    end

    def self.sql_calculate(command)
      sql_execute(command).first&.values&.first
    end

    def self.raw
      sql_execute all.to_sql
    end

    def self.as_sql
      SQLString.new(all.to_sql)
    end
  end

  class SQLString < String
    def execute
      ::Q::Core.sql_execute self
    end

    alias to_sql to_s
    alias inspect to_s
  end
end
