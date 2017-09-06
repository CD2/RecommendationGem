class ActiveRecord::Base
  delegate :sql_execute, :sql_calculate, to: :class

  class << self
    def sql_execute command
      ActiveRecord::Base.connection.execute(command).to_a
    end

    def sql_calculate command
      sql_execute(command).first&.values&.first
    end
  end
end

class ActiveRecord::Relation
  def raw
    ActiveRecord::Base.sql_execute to_sql
  end
end
