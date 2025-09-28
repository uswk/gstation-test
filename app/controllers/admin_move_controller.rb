class AdminMoveController < ApplicationController

  before_action :authenticate_user!

  # GET /admin_move
  def index
    @m_custom = MCustom.joins("LEFT JOIN m_combos ON m_combos.class_1='#{G_ADMIN_TYPE_CLASS_1}' and m_combos.class_2=0 and m_combos.class_code=m_customs.admin_type").joins("LEFT JOIN m_combos d ON d.class_1='#{G_DISTRICT_CLASS_1}' and d.class_2=0 and d.class_code=m_customs.district_code").where("m_customs.cust_kbn='#{G_CUST_KBN_ADMIN}' and m_customs.cust_code=?", params[:cust_code]).select("m_customs.*, m_combos.class_name, d.class_name as district").first
    @station_details = MCustom.where("cust_kbn='#{G_CUST_KBN_STATION}' and admin_code=?", params[:cust_code]).select("m_customs.*, case when delete_flg=1 then 'bgcolor=lightgrey' else '' end as bg_color").order("cust_code")
    render
  end

  # POST /admin_move
  def move
    if params[:next_flg]
      @m_custom_bef = MCustom.joins("LEFT JOIN m_combos ON m_combos.class_1='#{G_ADMIN_TYPE_CLASS_1}' and m_combos.class_2=0 and m_combos.class_code=m_customs.admin_type").joins("LEFT JOIN m_combos d ON d.class_1='#{G_DISTRICT_CLASS_1}' and d.class_2=0 and d.class_code=m_customs.district_code").where("m_customs.cust_kbn='#{G_CUST_KBN_ADMIN}' and m_customs.cust_code=?", params[:cust_code_bef][0]).select("m_customs.*, m_combos.class_name, d.class_name as district").first
      @m_custom_aft = MCustom.joins("LEFT JOIN m_combos ON m_combos.class_1='#{G_ADMIN_TYPE_CLASS_1}' and m_combos.class_2=0 and m_combos.class_code=m_customs.admin_type").joins("LEFT JOIN m_combos d ON d.class_1='#{G_DISTRICT_CLASS_1}' and d.class_2=0 and d.class_code=m_customs.district_code").where("m_customs.cust_kbn='#{G_CUST_KBN_ADMIN}' and m_customs.cust_code=?", params[:cust_code_aft][0]).select("m_customs.*, m_combos.class_name, d.class_name as district").first
      # 選択ステーション取得
      strwhere = "cust_kbn='#{G_CUST_KBN_STATION}' and cust_code in ("
      params[:move_chk].length.times do |i|
        if i!=0
          strwhere = strwhere + ","
        end
        strwhere = strwhere + params[:move_chk][i]
      end
      strwhere = strwhere + ")"
      @station_details = MCustom.where("#{strwhere}").select("m_customs.*, case when delete_flg=1 then 'bgcolor=lightgrey' else '' end as bg_color").order("cust_code")
      case params[:next_flg][0]
        when "1" then
          # 確認画面へ遷移
          @next_flg="2"
        when "2" then
          # 移動処理の確定
          @station_details.update_all(:admin_code => @m_custom_aft.cust_code)
          change_comment = @m_custom_bef.cust_code.to_s + ":" + @m_custom_bef.cust_name.to_s + " → " + @m_custom_aft.cust_code.to_s + ":" + @m_custom_aft.cust_name.to_s
          api_log_hists(402, 2, change_comment)
          logger.fatal(current_user.user_id.to_s + "_admin_move_upd")
          @next_flg="3"
        else
      end
      if @m_custom_aft.nil?
        @next_flg="9"  #管理者が存在しない時
      end
    end
    
    if params[:chg_flg]
      # 管理者情報取得
      @m_custom = MCustom.joins("LEFT JOIN m_combos c ON c.class_1='#{G_ADMIN_TYPE_CLASS_1}' and c.class_2=0 and c.class_code=m_customs.admin_type").where("m_customs.cust_kbn='#{G_CUST_KBN_ADMIN}' and m_customs.cust_code=?",params[:admin_code_new][0]).select("m_customs.cust_name, c.class_name").first
      if not @m_custom.nil?
        @cust_name = @m_custom.cust_name
        @admin_type = @m_custom.class_name
      else
        @cust_name = ""
        @admin_type = ""
      end
      @ajaxflg = 5
    end
  end
end
