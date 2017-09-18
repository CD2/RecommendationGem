# frozen_string_literal: true

module Recommendation
  module Recommendable
    module Tags
      extend ActiveSupport::Concern

      included do
        def self.tagged_with(*tag_names)
          options = tag_names.extract_options!.to_options
          options.assert_valid_keys(:allow_negative)
          allow_negative = options.fetch(:allow_negative, false)

          docs = ::Recommendation::Document
                 .where(recommendable_type: name)
                 .tagged_with(tag_names, allow_negative)
                 .select(:recommendable_id)
          where(id: docs)
        end

        def self.all_tags
          ::Recommendation::Document.where(recommendable_type: name).all_tags
        end
      end

      def tag_with(*args)
        args.extract_options!.each do |tag, weight|
          tag_name = ::Recommendation::Document.normalize(tag)
          recommendation_document.static_tags[tag_name] = weight
        end
        args.each do |tags|
          Array.wrap(tags).each do |tag|
            tag_name = ::Recommendation::Document.normalize(tag)
            recommendation_document.static_tags[tag_name] ||= 1
          end
        end
        recommendation_document.save
      end

      def remove_tag(*args)
        args.each do |tag|
          tag_name = ::Recommendation::Document.normalize(tag)
          recommendation_document.static_tags[tag_name] = 0
        end
        recommendation_document.save
      end

      def tags
        tags_hash.map { |tag, weight| { name: tag, weight: weight } }
      end

      def tags_hash
        recommendation_document.tags_cache.with_indifferent_access
      end

      def static_tags_hash
        recommendation_document.static_tags.with_indifferent_access
      end

      def dynamic_tags_hash
        result = tags_hash.merge(static_tags_hash) { |_k, v1, v2| v1 - v2 }
        result.reject { |_k, v| v.zero? }.to_h.with_indifferent_access
      end

      def recalculate_tags!
        recommendation_document.recalculate_tags
        recommendation_document.save!
        tags
      end
    end
  end
end
