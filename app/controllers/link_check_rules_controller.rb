# frozen_string_literal: true

# app/controllers/link_check_rules_controller.rb
class LinkCheckRulesController < ApplicationController
  before_action :authenticate_user!

  def index
    @link_check_rules = if params[:link_check_rule].present?
      LinkCheckRule.where(link_check_rule_params)
    else
      LinkCheckRule.all
    end
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
    @link_check_rule.update(link_check_rule_params)
    render json: @link_check_rule
  end

  private
    def link_check_rule_params
      params.require(:link_check_rule).permit(:source_id, :xpath, :status_codes, :active, :throttle,
                                              :collection_title, :_id, :created_at, :updated_at)
    end
end
