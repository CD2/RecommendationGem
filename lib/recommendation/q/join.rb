# frozen_string_literal: true

require_dependency "#{File.dirname(__FILE__)}/core.rb"

module Recommendation
  module Q
    class Core
      def self.inner_join(model, opts = {})
        join(model, 'INNER JOIN', opts)
      end

      def self.left_join(model, opts = {})
        join(model, 'LEFT JOIN', opts)
      end

      def self.right_join(model, opts = {})
        join(model, 'RIGHT JOIN', opts)
      end

      private

      def self.join(model, join_type, opts)
        options = opts.with_indifferent_access
        if model.respond_to? :to_sql
          target = "(#{model.to_sql})"
          options[:as] ||= 'subquery'
        end
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
          on = options[:on].map do |x|
            if x.is_a? Array
              "#{Q.quote(table_name, x[0])} = #{Q.quote(target_name, x[1])}"
            else
              x.to_s
            end
          end.join(' AND ')
        end
        joins("#{join_type} #{target}#{as} ON #{on}")
      end
    end
  end
end
