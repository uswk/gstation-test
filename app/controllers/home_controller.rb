class HomeController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :authenticate_user!, except: [:ajax2]

  def index
    @infomations = Infomation.order("info_date desc, id desc")
  end

  def ajax2
    respond_to do |format|
      format.js
    end
  end

  def test
  end
end
