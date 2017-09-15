# frozen_string_literal: true
# rubocop:disable all

Dir['./app/models/**/*.rb'].each { |file| require_dependency file }

module Recommendation
  class PagesController < ActionController::Base
    before_action :set_models
    before_action :set_model, except: :root
    before_action :set_record, except: %i[root index index_bounce]

    def root; end

    def index
      @params = params.permit!.slice(:tags, :limit, :offset)

      @tags = Array.wrap(params[:tags]) || []
      @limit = params[:limit].present? ? params[:limit].to_i : 10
      @offset = params[:offset].present? ? params[:offset].to_i : 0
      @records = @model.by_popularity(include_score: true).order(id: :asc).includes(:recommendation_document).limit(@limit).offset(@offset)
      @records = @records.tagged_with(*@tags, allow_negative: true) if @tags.present?

      @records.load
    end

    def show
      @params = params.permit!.slice(:vote_limit, :vote_offset, :target_model, :limit, :offset)

      @vote_limit = params[:vote_limit].present? ? params[:vote_limit].to_i : 10
      @vote_offset = params[:vote_offset].present? ? params[:vote_offset].to_i : 0
      @votes = @record.votes_as_voter.order(weight: :desc).includes(votable: :recommendation_document).limit(@vote_limit).offset(@vote_offset)
      @target_model = get_model(params[:target_model]) || @models.reject { |x| x == @model }.first
      @limit = params[:limit].present? ? params[:limit].to_i : 10
      @offset = params[:offset].present? ? params[:offset].to_i : 0

      @votes.load

      return @records = [] unless @target_model
      @records = @target_model.recommend_to(@record, include_score: true).order(id: :asc).limit(@limit).offset(@offset).includes(:recommendation_document)

      @records.load
    end

    def show_bounce
      params_string = params.permit!.slice(:target_model, :limit, :offset, :vote_limit, :vote_offset).to_param
      redirect_to "#{recommendation.root_path}#{unparse_model @model}/#{@record.id}?#{params_string}"
    end

    def index_bounce
      params_string = params.permit!.slice(:tags, :limit, :offset).to_param
      redirect_to "#{recommendation.root_path}#{unparse_model @model}/?#{params_string}"
    end

    def recalculate
      @record.recalculate_tags!
      redirect_to "#{recommendation.root_path}#{unparse_model @model}/#{@record.id}"
    end

    def parse_model(input)
      input.singularize.split('::').map(&:camelcase).join('::')
    end

    def unparse_model(input)
      input.name.split('::').map(&:underscore).join('::').pluralize
    end

    private

    def set_models
      @models = ::ApplicationRecord.descendants.select { |x| x.include?(Recommendable) }.sort_by(&:name)
    end

    def set_model
      render :bad_model unless @model = get_model
    end

    def get_model(input = params[:model])
      result = begin
                 parse_model(input).constantize
               rescue
                 nil
               end
      result.in?(@models) ? result : nil
    end

    def set_record
      @record = begin
                  @model.find(params[:id])
                rescue
                  nil
                end
      render :bad_record unless @record
    end
  end
end
