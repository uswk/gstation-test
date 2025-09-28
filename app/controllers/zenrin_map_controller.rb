class ZenrinMapController < ApplicationController

  before_action :set_zenrin_map_key
  before_action :authenticate_user!

  # GET /zenrin_map
  def index
    @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
    
    @def_address = A_DEF_ADDRESS
    @def_latitude = A_DEF_LATITUDE
    @def_longitude = A_DEF_LONGITUDE
    if params[:map_width].blank?
      @def_width = 800
    else
      @def_width = params[:map_width]
    end
    if params[:map_height].blank?
      @def_height = 500
    else
      @def_height = params[:map_height]
    end
    if params[:center_lat].blank?
      @def_latitude = A_DEF_LATITUDE
    else
      @def_latitude = params[:center_lat]
    end
    if params[:center_lng].blank?
      @def_longitude = A_DEF_LONGITUDE
    else
      @def_longitude = params[:center_lng]
    end
    
    @header_no_dsp = 1  #ヘッダ非表示
    
    render
  end
  
  def ajax
    #マーカー再描画
    northeast_lat = params[:northeast_lat][0]
    southwest_lat = params[:southwest_lat][0]
    northeast_lng = params[:northeast_lng][0]
    southwest_lng = params[:southwest_lng][0]

    @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
    custom_where = "(m_customs.cust_kbn='#{G_CUST_KBN_STATION}' or m_customs.cust_kbn='#{G_CUST_KBN_UNLOAD}') and m_customs.delete_flg=0 AND ( m_customs.latitude<='#{northeast_lat}' AND m_customs.latitude>='#{southwest_lat}' AND m_customs.longitude<='#{northeast_lng}' AND m_customs.longitude>='#{southwest_lng}')"
    #custom_where = custom_where + " AND (m_customs.start_date is null OR m_customs.start_date<='#@now_date')"
    #custom_where = custom_where + " AND (m_customs.end_date is null OR m_customs.end_date>='#@now_date')"
    
    @m_customs = MCustom.joins("LEFT JOIN m_customs admin on admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code")
    @m_customs = @m_customs.joins("left join m_combos type on type.class_1='#{G_ADMIN_TYPE_CLASS_1}' and type.class_2=0 and type.class_code=admin.admin_type")
    @m_customs = @m_customs.joins("left join (select min(mr.route_code) as route_code, mrp.cust_kbn, mrp.cust_code from m_routes mr inner join m_route_points mrp on mrp.route_code=mr.route_code where mr.delete_flg=0 and mrp.cust_kbn='#{G_CUST_KBN_STATION}' group by mrp.cust_kbn, mrp.cust_code) mrp on mrp.cust_kbn=m_customs.cust_kbn and mrp.cust_code=m_customs.cust_code")
    @m_customs = @m_customs.joins("left join m_routes mr on mr.route_code=mrp.route_code")
    @m_customs = @m_customs.joins("left join m_combos clr on clr.class_1='#{G_COLOR_PATTERN_CLASS_1}' and clr.class_2=0 and clr.class_code=mr.area_color")
    @m_customs = @m_customs.where("#{custom_where}")
    @m_customs = @m_customs.select("m_customs.*, admin.cust_name as admin_name, admin.tel_no as admin_tel, type.value as type_value, clr.value2 as marker_color, case when (m_customs.start_date is null OR m_customs.start_date<='#{@now_date}') AND (m_customs.end_date is null OR m_customs.end_date>='#{@now_date}') then '' else 'lightgrey' end as bgcolor")
    @m_customs = @m_customs.order("m_customs.cust_kbn, m_customs.cust_code")
  end

  private
  
  def set_zenrin_map_key
    @map_zenrin_cid = nil
    @map_zenrin_uid = nil
    @map_zenrin_pwd = nil
    @map_zenrin_url = nil
    @map_zenrin_tel = nil
    if not current_user.nil?
      @map_zenrin = MCombo.where("class_1=? AND class_name=?", G_ZENRIN_CLASS_1, current_user.user_id).first
      if not @map_zenrin.nil?
        @map_zenrin_cid = @map_zenrin.value.to_s
        @map_zenrin_uid = @map_zenrin.value2.to_s
        @map_zenrin_pwd = @map_zenrin.value3.to_s
        @map_zenrin_url = @map_zenrin.value4.to_s
        @map_zenrin_tel = @map_zenrin.value5.to_s
      end
    end
  end

end
