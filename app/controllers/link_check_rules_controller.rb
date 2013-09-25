class LinkCheckRulesController < ApplicationController

  respond_to :json

  def index
    @link_check_rules = params[:link_check_rule].present? ? LinkCheckRule.where(params[:link_check_rule]) : LinkCheckRule.all
    respond_with @link_check_rules
  end

  def show
    @link_check_rule = LinkCheckRule.find(params[:id])
    respond_with @link_check_rule
  end

  def destroy
    @link_check_rule = LinkCheckRule.find(params[:id])
    respond_with @link_check_rule.destroy
  end

  def create
    @link_check_rule = LinkCheckRule.create(params[:link_check_rule])
    respond_with @link_check_rule
  end

  def update
    @link_check_rule = LinkCheckRule.find(params[:id])
    @link_check_rule.update_attributes(params[:link_check_rule])
    respond_with @link_check_rule
  end
end