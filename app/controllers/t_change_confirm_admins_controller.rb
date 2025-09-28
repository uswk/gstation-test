class TChangeConfirmAdminsController < ApplicationController

  before_action :authenticate_user!

  # POST /t_change_confirm_admins
  def confirm
    # チェック分取得
    strwhere = "t_change_shinseis.id in ("
    params[:shinsei_chk].length.times do |i|
      if i!=0
        strwhere = strwhere + ","
      end
      strwhere = strwhere + params[:shinsei_chk][i]
    end
    strwhere = strwhere + ")"
    @t_change_shinseis = TChangeShinsei.joins("left join m_combos mc on mc.class_1='#{G_ADMIN_TYPE_CLASS_1}' and mc.class_2=0 and mc.class_code=t_change_shinseis.admin_type").joins("left join m_combos d on d.class_1='#{G_DISTRICT_CLASS_1}' and d.class_2=0 and d.class_code=t_change_shinseis.district_code").where("#{strwhere}").select("t_change_shinseis.*, mc.class_name as admin_type_name, d.class_name as district").order("t_change_shinseis.shinsei_date, t_change_shinseis.id")

    #一括更新処理
    if params[:confirm_flg]
      # トランザクション処理
      begin
        ActiveRecord::Base.transaction do
          @t_change_shinseis.each do |t_change_shinsei|
            MCustom.where("cust_kbn=? and cust_code=?", t_change_shinsei.cust_kbn, t_change_shinsei.cust_code).update_all(:cust_name => t_change_shinsei.cust_name, :admin_type => t_change_shinsei.admin_type, :district_code => t_change_shinsei.district_code, :district_name => t_change_shinsei.district_name, :seq => t_change_shinsei.seq, :addr_1 => t_change_shinsei.addr_1, :addr_2 => t_change_shinsei.addr_2, :email => t_change_shinsei.email, :tel_no => t_change_shinsei.tel_no, :fax_no => t_change_shinsei.fax_no)
            TChangeShinsei.where("id=?", t_change_shinsei.id).update_all(:confirm_flg => 1)
          end
          api_log_hists(1201, 7, "")
          logger.fatal(current_user.user_id.to_s + "_t_change_confirm_admins_upd")
          redirect_to t_change_shinsei_admins_url, notice: "一括更新処理が完了しました。"
        end
      rescue => e
        logger.fatal(current_user.user_id.to_s + "_t_change_confirm_admins_upd_err")
        redirect_to t_change_shinsei_admins_url, alert: "一括更新処理が失敗しました。"
      end
    end
  end
end
