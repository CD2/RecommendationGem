# frozen_string_literal: true

require_dependency "#{File.dirname(__FILE__)}/core.rb"

module Recommendation
  module Q
    class Core
      def self.expand_json(field, opts = {})
        options = opts.with_indifferent_access
        name = options[:as] || 'json'
        condition = options[:on] || 'TRUE'
        type = columns_hash[field.to_s]&.type == :jsonb ? 'jsonb' : 'json'
        joins("LEFT JOIN #{type}_each_text(#{field}) AS #{name} ON #{condition}")
      end
    end
  end
end
