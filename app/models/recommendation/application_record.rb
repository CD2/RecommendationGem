require_dependency "#{Recommendation::Engine.root}/lib/q/query_chain.rb"

module Recommendation
  class ApplicationRecord < Q::ApplicationRecord
    self.abstract_class = true

    def self.expand_json field, opts  = {}
      options = opts.with_indifferent_access
      name = options[:as] || 'json'
      condition = options[:on] || 'TRUE'
      type = columns_hash[field.to_s]&.type == :jsonb ? 'jsonb' : 'json'
      joins("JOIN #{type}_each_text(#{field}) AS #{name} ON #{condition}")
    end
  end
end
