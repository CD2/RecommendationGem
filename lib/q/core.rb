module Q
  def self.quote *args
    args.join('.').gsub('"', '').split('.').map do |x|
      x.to_s == '*' ? '*' : "\"#{x}\""
    end.join('.')
  end

  class Core < ::ActiveRecord::Base
    self.abstract_class = true

    delegate :raw, :sql_execute, :sql_calculate, to: :class

    def sql_execute command
      connection.execute(command).to_a
    end

    def sql_calculate command
      sql_execute(command).first&.values&.first
    end

    def raw
      sql_execute to_sql
    end
  end
end
