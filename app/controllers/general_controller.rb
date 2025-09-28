class GeneralController < ApplicationController

  before_action :set_map_key
  before_action :set_zenrin_map_key
  before_action :authenticate_user!, :if => :my_condition?

  # GET /general
  def index
    @now_yobi = Time.now.wday # 現在の曜日を取得
    @now_week = ((Time.now.day+6)/7).truncate # 現在の週を取得
    @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
    
    @m_combo = MCombo.where("class_1=? AND class_2=0 AND class_code=?", G_YOBI_CLASS_1, @now_yobi).first
    @def_address = A_DEF_ADDRESS
    @def_latitude = A_DEF_LATITUDE
    @def_longitude = A_DEF_LONGITUDE
    
#    if @map_zenrin_cid.blank?
      @google_map_display = ""
      @zenrin_map_display = "display:none;"

#    else
#      @google_map_display = "visibility:hidden;"
#      @zenrin_map_dispaly = ""
#    end
    
    render
  end
  
  def ajax
    #マーカー再描画
    northeast_lat = params[:northeast_lat][0]
    southwest_lat = params[:southwest_lat][0]
    northeast_lng = params[:northeast_lng][0]
    southwest_lng = params[:southwest_lng][0]
    @map_type = params[:map_type][0]

    @now_yobi = Time.now.wday # 現在の曜日を取得
    @now_week = ((Time.now.day+6)/7).truncate # 現在の週を取得
    @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
    custom_where = "m_customs.cust_kbn='#{G_CUST_KBN_STATION}' and m_customs.delete_flg=0 and r.delete_flg=0 AND ((rr.run_week=0 AND rr.run_yobi='#{@now_yobi}') OR (rr.run_week='#{@now_week}' AND rr.run_yobi='#{@now_yobi}')) AND ( m_customs.latitude<='#{northeast_lat}' AND m_customs.latitude>='#{southwest_lat}' AND m_customs.longitude<='#{northeast_lng}' AND m_customs.longitude>='#{southwest_lng}')"
    custom_where = custom_where + " AND (m_customs.start_date is null OR m_customs.start_date<='#@now_date')"
    custom_where = custom_where + " AND (m_customs.end_date is null OR m_customs.end_date>='#@now_date')"
    @m_customs = MCustom.joins("INNER JOIN m_route_points rp ON rp.cust_kbn=m_customs.cust_kbn AND rp.cust_code=m_customs.cust_code")
    @m_customs = @m_customs.joins("INNER JOIN m_routes r ON r.route_code=rp.route_code")
    @m_customs = @m_customs.joins("INNER JOIN m_route_rundates rr ON rr.route_code=r.route_code")
    @m_customs = @m_customs.joins("LEFT JOIN m_combos c ON c.class_1='#{G_ITEM_CLASS_1}' AND c.class_2=0 AND c.class_code=rr.item_kbn")
    @m_customs = @m_customs.joins("LEFT JOIN (SELECT cust_kbn, cust_code, MAX(finish_timing) AS finish_timing FROM t_collect_lists WHERE finish_timing is not null AND out_timing >= '#{@now_date}' AND out_timing< '#{@now_date.to_date+1}' GROUP BY cust_kbn, cust_code) cl ON cl.cust_kbn=rp.cust_kbn AND cl.cust_code=rp.cust_code")
    @m_customs = @m_customs.where("#{custom_where}")
    @m_customs = @m_customs.select("m_customs.id, m_customs.cust_kbn, m_customs.cust_code, m_customs.cust_name, m_customs.latitude, m_customs.longitude, cl.finish_timing, '1' AS mikaishu_count, '' AS mikaishu_name, '' AS info, -4 AS window_id, group_concat(DISTINCT concat('<img src=', c.value, '>&nbsp;') ORDER BY rr.item_kbn SEPARATOR '') as item_value")
    @m_customs = @m_customs.group("m_customs.cust_code, m_customs.cust_name, m_customs.latitude, m_customs.longitude, cl.finish_timing")
    iCount = 0
    @m_customs.each do |custom|
      @info_text = custom.item_value.to_s
      @m_customs[iCount].info = ERB::Util.url_encode(@info_text + "<br><br>")
      if custom.finish_timing.nil?
        @m_customs[iCount].info = ERB::Util.url_encode(@info_text + "<br><h3>&nbsp;<font color=red>本日の回収は終わっていません。</font></h3>")
      else
        @m_customs[iCount].info = ERB::Util.url_encode(@info_text + "<br><h3>&nbsp;回収時間 ： <font color=blue>" + custom.finish_timing.try(:strftime, "%Y/%m/%d %H:%M:%S") + "</font></h3>")
      end
      iCount = iCount + 1
    end
    @m_combo = MCombo.where("class_1=? AND class_2=0 AND class_code=?", G_YOBI_CLASS_1, @now_yobi).first
  end

  private
  
  def set_map_key
    @map_key = A_DEF_MAP_KEY
  end
  
  def set_zenrin_map_key
    @map_zenrin_cid = nil
    @map_zenrin_uid = nil
    @map_zenrin_pwd = nil
    @map_zenrin_tel = nil
    @map_zenrin_url = nil
    if not current_user.nil?
      @map_zenrin = MCombo.where("class_1=? AND class_name=?", G_ZENRIN_CLASS_1, current_user.user_id).first
      if not @map_zenrin.nil?
        @map_zenrin_cid = @map_zenrin.value.to_s
        @map_zenrin_uid = @map_zenrin.value2.to_s
        @map_zenrin_pwd = @map_zenrin.value3.to_s
        @map_zenrin_tel = @map_zenrin.value5.to_s
        @map_zenrin_url = @map_zenrin.value4.to_s
      end
    end
  end
  
  def my_condition?
    if A_DEF_GENERAL_AUTHORITY == 'false'
      return false
    else
      return true
    end
  end
end
