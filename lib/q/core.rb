# frozen_string_literal: true

module Q
  def self.quote(*args)
    args.join('.').delete('"').split('.').map do |x|
      x.to_s == '*' ? '*' : "\"#{x}\""
    end.join('.')
  end

  class Core < ::ActiveRecord::Base
    self.abstract_class = true

    delegate :raw, :sql_execute, :sql_calculate, to: :class

    def self.sql_execute(command)
      connection.execute(command).to_a
    end

    def self.sql_calculate(command)
      sql_execute(command).first&.values&.first
    end

    def self.raw
      sql_execute all.to_sql
    end
  end
end
