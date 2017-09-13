Dir['./app/models/**/*.rb'].each { |file| require_dependency file }

class PagesController < ApplicationController
  before_action :set_models
  before_action :set_model, except: :root
  before_action :set_record, except: %i[root index]

  def root ; end

  def index; end

  def show; end

  def recalculate
    @record.recalculate_tags!
    redirect_to "/#{@model.name.underscore.pluralize}/#{@record.id}"
  end

  private

  def set_models
    @models = ApplicationRecord.descendants.select { |x| x.include?(Recommendable) }
  end

  def set_model
    @model = params[:model]&.singularize&.camelcase.constantize rescue nil
    render :bad_model unless @model.in? @models
  end

  def set_record
    @record = @model.find(params[:id]) rescue nil
    render :bad_record unless @record
  end
end
