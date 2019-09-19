# frozen_string_literal: true
class LinkCheckRulesController < ApplicationController
  before_action :authenticate_user!

  def index
    @link_check_rules = params[:link_check_rule].present? ? LinkCheckRule.where(link_check_rule_params) : LinkCheckRule.all
    render json: @link_check_rules
  end

  def show
    @link_check_rule = LinkCheckRule.find(params[:id])
    render json: @link_check_rule
  end

  def destroy
    @link_check_rule = LinkCheckRule.find(params[:id])
    render json: @link_check_rule.destroy
  end

  def create
    @link_check_rule = LinkCheckRule.create!(link_check_rule_params)
    render json: @link_check_rule
  end

  def update
    @link_check_rule = LinkCheckRule.find(params[:id])
    @link_check_rule.update_attributes(link_check_rule_params)
    render json: @link_check_rule
  end

  private

  def link_check_rule_params
    params.require(:link_check_rule).permit!
  end
end
