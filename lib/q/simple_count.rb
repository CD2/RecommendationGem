require_dependency "#{File.dirname(__FILE__)}/core.rb"

module Q
  def self.simple_count(model, arg = :id)
    str = case(arg.class.name)
    when 'Hash'
      quote(arg.first[0], arg.first[1])
    when 'Symbol'
      quote(model.table_name, arg)
    else
      arg.to_s
    end
    Core.sql_calculate(model.except(:select, :order).select("COUNT(#{str})").to_sql)
  end

  class Core
    def self.simple_count(arg = :id)
      Q.simple_count(all, arg)
    end
  end
end
