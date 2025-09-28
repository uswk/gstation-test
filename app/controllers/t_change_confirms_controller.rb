class TChangeConfirmsController < ApplicationController

  before_action :authenticate_user!

  # POST /t_change_confirms
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
    @t_change_shinseis = TChangeShinsei.joins("left join m_customs st on st.cust_kbn=t_change_shinseis.cust_kbn and st.cust_code=t_change_shinseis.cust_code").joins("left join m_combos mc on mc.CLASS_1='#{G_SHINSEI_CLASS_1}' and mc.CLASS_2=0 and mc.CLASS_CODE=t_change_shinseis.shinsei_kbn").joins("left join m_customs admin on admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=t_change_shinseis.admin_code").joins("left join m_routes mr on mr.route_code=t_change_shinseis.route_code").where("#{strwhere}").select("t_change_shinseis.*, mc.class_name as shinsei_name, admin.cust_name as admin_name, mr.route_name").order("t_change_shinseis.shinsei_date, t_change_shinseis.id")

    #一括更新処理
    if params[:confirm_flg]
      # トランザクション処理
      begin
        ActiveRecord::Base.transaction do
          @t_change_shinseis.each do |t_change_shinsei|
            case t_change_shinsei.shinsei_kbn.to_s
              when "1" then  # 新設
                MCustom.where("cust_kbn=? and cust_code=?", t_change_shinsei.cust_kbn, t_change_shinsei.cust_code).update_all(:addr_1 => t_change_shinsei.addr_1, :addr_2 => t_change_shinsei.addr_2, :latitude => t_change_shinsei.latitude, :longitude => t_change_shinsei.longitude, :admin_code => t_change_shinsei.admin_code, :shinsei_date => t_change_shinsei.shinsei_date, :start_date => t_change_shinsei.kibou_date, :cust_name => t_change_shinsei.cust_name, :use_content => t_change_shinsei.use_content, :setai_count => t_change_shinsei.setai_count, :use_count => t_change_shinsei.use_count, :memo => t_change_shinsei.memo)
                #収集区追加
                @m_route_points = MRoutePoint.where("route_code=? and cust_kbn=? and cust_code=?", t_change_shinsei.route_code, t_change_shinsei.cust_kbn, t_change_shinsei.cust_code).first
                if @m_route_points.nil?
                  # 別収集区分削除
                  @m_route_point_dlts = MRoutePoint.where("route_code<>? and cust_kbn=? and cust_code=?", t_change_shinsei.route_code, t_change_shinsei.cust_kbn, t_change_shinsei.cust_code)
                  @m_route_point_dlts.each do |m_route_point_dlt|
                    m_route_point_dlt.destroy
                  end
                  # 収集区に追加
                  tree_no = MRoutePoint.where("route_code=?", t_change_shinsei.route_code).maximum(:tree_no).to_i + 1
                  @m_route_point = MRoutePoint.new(:route_code => t_change_shinsei.route_code, :tree_no=> tree_no, :cust_kbn => t_change_shinsei.cust_kbn, :cust_code => t_change_shinsei.cust_code)
                  @m_route_point.save!
                end
              when "2" then  # 変更
                MCustom.where("cust_kbn=? and cust_code=?", t_change_shinsei.cust_kbn, t_change_shinsei.cust_code).update_all(:addr_1 => t_change_shinsei.addr_1, :addr_2 => t_change_shinsei.addr_2, :latitude => t_change_shinsei.latitude, :longitude => t_change_shinsei.longitude, :admin_code => t_change_shinsei.admin_code, :cust_name => t_change_shinsei.cust_name, :use_content => t_change_shinsei.use_content, :setai_count => t_change_shinsei.setai_count, :use_count => t_change_shinsei.use_count, :memo => t_change_shinsei.memo)
                #収集区更新
                @m_route_points = MRoutePoint.where("route_code=? and cust_kbn=? and cust_code=?", t_change_shinsei.route_code, t_change_shinsei.cust_kbn, t_change_shinsei.cust_code).first
                if @m_route_points.nil?
                  # 別収集区分削除
                  @m_route_point_dlts = MRoutePoint.where("route_code<>? and cust_kbn=? and cust_code=?", t_change_shinsei.route_code, t_change_shinsei.cust_kbn, t_change_shinsei.cust_code)
                  @m_route_point_dlts.each do |m_route_point_dlt|
                    m_route_point_dlt.destroy
                  end
                  # 収集区に追加
                  tree_no = MRoutePoint.where("route_code=?", t_change_shinsei.route_code).maximum(:tree_no).to_i + 1
                  @m_route_point = MRoutePoint.new(:route_code => t_change_shinsei.route_code, :tree_no=> tree_no, :cust_kbn => t_change_shinsei.cust_kbn, :cust_code => t_change_shinsei.cust_code)
                  @m_route_point.save!
                end
              when "3" then  # 廃止
                MCustom.where("cust_kbn=? and cust_code=?", t_change_shinsei.cust_kbn, t_change_shinsei.cust_code).update_all(:addr_1 => t_change_shinsei.addr_1, :addr_2 => t_change_shinsei.addr_2, :latitude => t_change_shinsei.latitude, :longitude => t_change_shinsei.longitude, :admin_code => t_change_shinsei.admin_code, :haishi_date => t_change_shinsei.shinsei_date, :end_date => t_change_shinsei.kibou_date, :cust_name => t_change_shinsei.cust_name, :use_content => t_change_shinsei.use_content, :setai_count => t_change_shinsei.setai_count, :use_count => t_change_shinsei.use_count, :memo => t_change_shinsei.memo)
                #収集区削除
                @m_route_point_dlts = MRoutePoint.where("cust_kbn=? and cust_code=?", t_change_shinsei.cust_kbn, t_change_shinsei.cust_code)
                @m_route_point_dlts.each do |m_route_point_dlt|
                  m_route_point_dlt.destroy
                end
              else
            end
            TChangeShinsei.where("id=?", t_change_shinsei.id).update_all(:confirm_flg => 1)
          end
          api_log_hists(302, 7, "")
          logger.fatal(current_user.user_id.to_s + "_t_change_confirms_upd")
          redirect_to t_change_shinseis_url, notice: "一括更新処理が完了しました。"
        end
      rescue => e
        logger.fatal(current_user.user_id.to_s + "_t_change_confirms_upd_err")
        redirect_to t_change_shinseis_url, alert: "一括更新処理が失敗しました。"
      end
    end
  end
end
