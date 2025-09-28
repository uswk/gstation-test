class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  # 緯度経度設定
  @common_0 = MCombo.where("class_1=0 and class_2=0 and class_code=1").first
  A_DEF_ADDRESS = @common_0.value
  A_DEF_LATITUDE = @common_0.value2
  A_DEF_LONGITUDE = @common_0.value3
  A_DEF_MAP_KEY = @common_0.value4.to_s
  A_DEF_GENERAL_AUTHORITY = @common_0.value5.to_s

  #@fee_gass = MComboBig.where("class_1=#{G_FEE_GASS_1}")
  #A_DEF_FEE_GASS_FLG = @fee_gass.nil? ? 0 : 1

  # ログ書き出し
  def api_log_hists(menu_id, change_type, change_comment)
    TLogHist.create(:log_time => Time.now, :user_id => current_user.id, :menu_id => menu_id, :change_type => change_type, :change_comment => change_comment)
  end

  protected

  def configure_permitted_parameters
    attributes = [:user_id, :password, :remember_me, :user_name, :authority]
    devise_parameter_sanitizer.permit(:sign_in, keys: attributes)
    devise_parameter_sanitizer.permit(:sign_up, keys: attributes)
  end
end
