# frozen_string_literal: true

module Recommendation
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

      def self.raw_pretty
        records = raw
        def records.inspect
          ''
        end
        return records unless records.any?
        columns = records.first.keys
        console_width = `tput cols`.to_f

        max_lengths = []
        records.first.each do |k, _v|
          max_length = records.map { |x| x[k].inspect.size }.max
          max_length = k.size if k.size > max_length
          max_length += 2
          max_lengths << max_length
        end

        while (max_lengths.sum + max_lengths.count - 1) > console_width
          max_lengths[max_lengths.index(max_lengths.max)] -= 1
        end

        puts
        draw_row columns, max_lengths, inspect: false
        puts max_lengths.map { |x| '-' * x }.join '+'
        records.each do |row|
          draw_row row.values, max_lengths
        end
      end

      def self.as_sql
        SQLString.new(all.to_sql)
      end

      private

      def self.draw_row items, limits, opts = {}
        options = { inspect: true }.merge(opts.to_options)
        items.size.times do |i|
          item = options[:inspect] ? items[i].inspect : items[i].to_s
          if item.size > limits[i]
            items[i] = item[0...(limits[i]-3)] + '...'
          else
            diff = limits[i] - item.size
            padding1 = padding2 = ' ' * (diff / 2.0)
            padding2 = padding2 + ' ' if diff.odd?
            items[i] = padding1 + item + padding2
          end
        end
        puts items.join '|'
      end
    end

    class SQLString < String
      def execute
        ::Recommendation::Q::Core.sql_execute self
      end

      alias to_sql to_s
      alias inspect to_s
    end
  end
end
