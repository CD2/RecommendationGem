# frozen_string_literal: true

module Recommendation
  module Recommendable
    module Tags
      extend ActiveSupport::Concern

      included do
        def self.tagged_with(*tag_names)
          options = tag_names.extract_options!.to_options
          options.assert_valid_keys(:allow_negative, :require_all)
          allow_negative = options.fetch(:allow_negative, false)
          require_all = options.fetch(:require_all, true)

          docs = ::Recommendation::Document
                 .where(recommendable_type: name)
                 .tagged_with(tag_names, allow_negative, !require_all)
                 .select(:recommendable_id)
          where(id: docs)
        end

        def self.all_tags
          tags = ::Recommendation::Document.where(
            recommendable_type: all.klass.name,
            recommendable_id: all.select(:id)
          ).all_tags
          ::Recommendation::Document.remove_special_tags(tags)
        end

        def self.all_special_tags
          tags = ::Recommendation::Document.where(
            recommendable_type: all.klass.name,
            recommendable_id: all.select(:id)
          ).all_tags
          ::Recommendation::Document.only_special_tags(tags)
        end

        def self.ordered_tags
          tags = ::Recommendation::Document
            .where(
              recommendable_type: all.klass.name,
              recommendable_id: all.select(:id)
            )
            .expand_json(:tags_cache)
            .group('json.key')
            .order('COUNT(json.value) DESC')
            .pluck('json.key')
          ::Recommendation::Document.remove_special_tags(tags)
        end

        after_save :tag_with_unsaved_tags
      end

      def tag_with(*args)
        return false unless recommendation_document
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
        return false unless recommendation_document
        args.each do |tag|
          tag_name = ::Recommendation::Document.normalize(tag)
          recommendation_document.static_tags[tag_name] = 0
        end
        recommendation_document.save
      end

      def tags
        tags_hash.map { |tag, weight| { name: tag, weight: weight } }
      end

      def tags= *tags
        tags.replace(Array.wrap(tags[0])) if tags.one?
        tags.map!(&:to_sym)
        @unsaved_static_tags_hash = tags.map { |x| [x, 1] }.to_h
      end

      def tag_with_unsaved_tags
        return unless @unsaved_static_tags_hash
        recommendation_document.update!(static_tags: @unsaved_static_tags_hash)
        @unsaved_static_tags_hash = nil
      end

      def tags_hash
        return {} unless recommendation_document
        recommendation_document.instance_eval do
          remove_special_tags(tags_cache).with_indifferent_access
        end
      end

      def static_tags_hash
        return {} unless recommendation_document
        recommendation_document.instance_eval do
          remove_special_tags(static_tags).with_indifferent_access
        end
      end

      def dynamic_tags_hash
        result = tags_hash.merge(static_tags_hash) { |_k, v1, v2| v1 - v2 }
        result.reject { |_k, v| v.zero? }.to_h.with_indifferent_access
      end

      def special_tags_hash
        return {} unless recommendation_document
        recommendation_document.instance_eval do
          h = only_special_tags(tags_cache)
          result = {}
          h.keys.each do |k|
            type, name = parse_special_tag(k)
            result[type] ||= {}
            result[type][name] = h[k]
          end
          result.with_indifferent_access
        end
      end

      def static_special_tags_hash
        return {} unless recommendation_document
        recommendation_document.instance_eval do
          h = only_special_tags(static_tags)
          result = {}
          h.keys.each do |k|
            type, name = parse_special_tag(k)
            result[type] ||= {}
            result[type][name] = h[k]
          end
          result.with_indifferent_access
        end
      end

      def dynamic_special_tags_hash
        special_tags_hash
        .deep_merge(static_special_tags_hash) { |_k, v1, v2| v1 - v2 }
        .map { |k1, v1| [k1, v1.reject { |_k2, v2| v2.zero? }.to_h] }.to_h
        .with_indifferent_access
      end

      def recalculate_tags!
        if recommendation_document
          recommendation_document.recalculate_tags
          recommendation_document.save!
        end
        tags
      end

      def model_tags
        (special_tags_hash[:model] || []).map do |tag, weight|
          { name: tag, weight: weight }
        end
      end
    end
  end
end
