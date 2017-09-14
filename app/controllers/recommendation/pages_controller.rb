Dir['./app/models/**/*.rb'].each { |file| require_dependency file }

module Recommendation
  class PagesController < ApplicationController
    before_action :set_models
    before_action :set_model, except: :root
    before_action :set_record, except: %i[root index]

    def root ; end

    def index
      @records = @model.by_popularity(include_score: true).order(id: :asc)
    end

    def show
      @votes_as_voter = @record.votes_as_voter.order(weight: :desc).includes(votable: :recommendation_document)
      @votes_as_votable = @record.votes_as_votable.order(weight: :desc).includes(:voter)
      @target_model = get_model(params[:target_model])
      @limit = params[:limit]&.to_i || 10
      @offset = params[:offset]&.to_i || 0
      return @records = [] unless @target_model
      @records = @target_model.recommend_to(@record, include_score: true).limit(@limit).offset(@offset).includes(:recommendation_document)
    end

    def show_bounce
      params_string = params.permit!.slice(:target_model, :limit, :offset).to_param
      redirect_to "#{recommendation.root_path}#{@model.name.underscore.pluralize}/#{@record.id}?#{params_string}"
    end

    def recalculate
      @record.recalculate_tags!
      redirect_to "#{recommendation.root_path}#{@model.name.underscore.pluralize}/#{@record.id}"
    end

    private

    def set_models
      @models = ::ApplicationRecord.descendants.select { |x| x.include?(Recommendable) }
    end

    def set_model
      render :bad_model unless @model = get_model
    end

    def get_model(input = params[:model])
      result = input.singularize.camelcase.constantize rescue nil
      result.in?(@models) ? result : nil
    end

    def set_record
      @record = @model.find(params[:id]) rescue nil
      render :bad_record unless @record
    end
  end
end
