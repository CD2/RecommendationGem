# frozen_string_literal: true

module Recommendable
  extend ActiveSupport::Concern

  included do
    has_one :recommendation_document, as: :recommendable, inverse_of: :recommendable, class_name: 'Recommendation::Document'
    has_many :votes_as_voter, as: :voter, inverse_of: :voter, class_name: 'Recommendation::Vote'
    has_many :votes_as_votable, as: :votable, inverse_of: :votable, class_name: 'Recommendation::Vote'

    def self.tagged_with(*tag_names)
      docs = Recommendation::Document
             .where(recommendable_type: name)
             .tagged_with(*tag_names)
             .select(:recommendable_id)
      where(id: docs)
    end

    def self.all_tags
      Recommendation::Document.where(recommendable_type: name).all_tags
    end

    def self.recommend_to(subject, opts = {})
      options = opts.to_options
      options.assert_valid_keys(:exclude_self, :include_score, :order, :consider)
      exclude_self = options.fetch(:exclude_self, true)
      include_score = options.fetch(:include_score, false)
      order_results = options.fetch(:order, true)
      consider = options.fetch(:consider, :tags)

      return by_tags(subject, opts) unless options[:consider]

      raise NotImplementedError

      influences = Array.wrap(consider)
      influences_hash = influences.extract_options!
      influences.each { |x| influences_hash[x] ||= 1 }

      Recommendation::Document.composite(all, subject, influences_hash)
    end

    def self.by_tags(subject, opts = {})
      options = opts.to_options
      options.assert_valid_keys(:exclude_self, :include_score, :order)
      exclude_self = options.fetch(:exclude_self, true)
      include_score = options.fetch(:include_score, false)
      order_results = options.fetch(:order, true)

      scores = Recommendation::Document.by_tags(all, subject)

      result = all

      if exclude_self && subject.is_a?(all.klass)
        result = result.where.not(id: subject.id)
      end

      if include_score
        result = result.select(Q.quote(table_name, :*)) if result.select_values.empty?
        result = result.select('coalesce(recommendation.score, 0) AS recommendation_score')
      end

      if order_results
        result = result.order('coalesce(recommendation.score, 0) DESC')
      end

      result.joins("LEFT JOIN (#{scores}) AS recommendation ON recommendation.recommendable_id = #{table_name}.id")
    end

    def self.by_popularity(opts = {})
      options = opts.to_options
      options.assert_valid_keys(:include_score, :order)
      include_score = options.fetch(:include_score, false)
      order_results = options.fetch(:order, true)

      scores = left_joins(:votes_as_votable)
               .group(:id)
               .select(:id)
               .select('SUM(recommendation_votes.weight) AS score')
               .to_sql

      result = all

      if include_score
        result = result.select(Q.quote(table_name, :*)) if result.select_values.empty?
        result = result.select('coalesce(popularity.score, 0) AS popularity_score')
      end

      if order_results
        result = result.order('coalesce(popularity.score, 0) DESC')
      end

      result.joins("LEFT JOIN (#{scores}) AS popularity ON popularity.id = #{table_name}.id")
    end

    def self.by_distance_to(subject, opts = {})
      options = opts.to_options
      options.assert_valid_keys(:exclude_self, :include_distance, :order)
      exclude_self = options.fetch(:exclude_self, true)
      include_distance = options.fetch(:include_distance, false)
      order_results = options.fetch(:order, true)

      distances = Recommendation::Document.by_distance(all, subject.recommendation_document)

      result = all

      if exclude_self && subject.is_a?(all.klass)
        result = result.where.not(id: subject.id)
      end

      if include_distance
        result = result.select(Q.quote(table_name, :*)) if result.select_values.empty?
        result = result.select('distances.distance')
      end

      if order_results
        result = result.order('distances.distance ASC NULLS LAST')
      end

      result.joins("LEFT JOIN (#{distances}) AS distances ON distances.recommendable_id = #{table_name}.id")
    end

    def self.by_time(opts = {})
      options = opts.to_options
      options.assert_valid_keys(:include_score, :order)
      include_score = options.fetch(:include_score, false)
      order_results = options.fetch(:order, true)

      scores = Recommendation::Document.by_time(all)

      result = all

      if include_score
        result = result.select(Q.quote(table_name, :*)) if result.select_values.empty?
        result = result.select('r_times.score AS age_score')
      end

      if order_results
        result = result.order('r_times.score DESC')
      end

      result.joins("LEFT JOIN (#{scores}) AS r_times ON r_times.id = #{table_name}.id")
    end
  end

  def recommendation_document
    super || create_recommendation_document!
  end

  def tag_with(*args)
    args.extract_options!.each do |tag, weight|
      recommendation_document.static_tags[Recommendation::Document.normalize(tag)] = weight
    end
    args.each do |tags|
      Array.wrap(tags).each do |tag|
        recommendation_document.static_tags[Recommendation::Document.normalize(tag)] ||= 1
      end
    end
    recommendation_document.save
  end

  def remove_tag(*args)
    args.each do |tag|
      recommendation_document.static_tags[Recommendation::Document.normalize(tag)] = 0
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

  def recommendation_score_for(subject)
    subject.class.where(id: subject.id)
           .recommend_to(self).pluck(:recommendation_score).first
  end

  def vote_up(votable)
    vote = votes_as_voter.find_or_initialize_by(votable: votable)
    return false unless vote.update(weight: 1)
    association(:recommendation_document).reset
    true
  end

  def vote_down(votable)
    vote = votes_as_voter.find_or_initialize_by(votable: votable)
    return false unless vote.update(weight: -1)
    association(:recommendation_document).reset
    true
  end

  def unvote(votable)
    vote = votes_as_voter.find_by(votable: votable)
    return false unless vote&.destroy
    association(:recommendation_document).reset
    true
  end

  def popularity_score(force = false)
    !force && attributes['popularity_score'] || votes_as_votable.pluck(:weight).sum
  end

  def distance_to(subject)
    subject.class.where(id: subject.id)
           .by_distance_to(self).pluck('distances.distance').first
  end

  def coordinates
    [recommendation_document.lat, recommendation_document.lng]
  end
end
