require_dependency "#{Recommendation::Engine.root}/lib/q/join.rb"
require_dependency "#{Recommendation::Engine.root}/lib/q/table_mock.rb"
require_dependency "#{Recommendation::Engine.root}/lib/q/query_chain.rb"

module Recommendation
  def self.all_tags
    Document.all_tags
  end

  def self.tagged_with tag_name
    Document.tagged_with(tag_name)
  end

  class ApplicationRecord < Q::Core
    self.abstract_class = true

    def self.expand_json field, opts  = {}
      options = opts.with_indifferent_access
      name = options[:as] || 'json'
      condition = options[:on] || 'TRUE'
      type = columns_hash[field.to_s]&.type == :jsonb ? 'jsonb' : 'json'
      joins("JOIN #{type}_each_text(#{field}) AS #{name} ON #{condition}")
    end

    delegate :normalize, to: :class

    def self.normalize(name)
      name.to_s.parameterize.tr('_-', ' ')
    end
  end
end
