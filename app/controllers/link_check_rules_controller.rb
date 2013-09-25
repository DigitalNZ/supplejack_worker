class CollectionRulesController < ApplicationController

  respond_to :json

  def index
    @collection_rules = params[:collection_rules].present? ? CollectionRules.where(params[:collection_rules]) : CollectionRules.all
    respond_with @collection_rules
  end

  def show
    @collection_rule = CollectionRules.find(params[:id])
    respond_with @collection_rule
  end

  def destroy
    @collection_rule = CollectionRules.find(params[:id])
    respond_with @collection_rule.destroy
  end

  def create
    @collection_rule = CollectionRules.create(params[:collection_rules])
    respond_with @collection_rule
  end

  def update
    @collection_rule = CollectionRules.find(params[:id])
    @collection_rule.update_attributes(params[:collection_rules])
    respond_with @collection_rule
  end
end