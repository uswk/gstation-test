class OutputMapsController < ApplicationController

  before_action :authenticate_user!
  before_action :set_map_key
  before_action :set_zenrin_map_key

  # GET /output_maps
  def index
    # 収集区
    if current_user.itaku_code.blank?
      routewhere = "m_routes.delete_flg = 0"
    else
      routewhere = "m_routes.delete_flg = 0 and mrr.itaku_code = '#{current_user.itaku_code}'"
    end
    @route_codes = MRoute.joins("left join m_route_rundates mrr on mrr.route_code=m_routes.route_code")
    @route_codes = @route_codes.where("#{routewhere}").group("m_routes.route_code, m_routes.route_name").order("m_routes.route_code asc").map{|i| [i.route_code.to_s + ':' + i.route_name.to_s, i.route_code] }
  end
  
  # POST /output_maps
  def output
    @route_code = params[:search_route][:query]
    @header_no_dsp = 1
    @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
    
    @m_route_areas = MRouteArea.joins("INNER JOIN m_routes r ON r.route_code=m_route_areas.route_code")
    @m_route_areas = @m_route_areas.joins("left join m_combos mc on mc.class_1='#{G_COLOR_PATTERN_CLASS_1}' and mc.class_2=0 and mc.class_code=r.area_color")
    @m_route_areas = @m_route_areas.where("m_route_areas.route_code=?", @route_code).select("m_route_areas.*,r.route_name,mc.value as area_color_value").order("m_route_areas.route_code")
    @m_route_point = MRoutePoint.joins("INNER JOIN m_customs c ON c.cust_kbn=m_route_points.cust_kbn AND c.cust_code = m_route_points.cust_code").where("m_route_points.route_code=?", @route_code).select("c.latitude, c.longitude").order("m_route_points.tree_no").first
    @m_customs = MCustom.joins("INNER JOIN m_route_points rp ON rp.cust_kbn=m_customs.cust_kbn AND rp.cust_code=m_customs.cust_code AND rp.route_code='#{@route_code}'")
    @m_customs = @m_customs.joins("LEFT JOIN m_customs admin ON admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code")
    @m_customs = @m_customs.joins("left join m_combos type on type.class_1='#{G_ADMIN_TYPE_CLASS_1}' and type.class_2=0 and type.class_code=admin.admin_type")
    @m_customs = @m_customs.where("m_customs.delete_flg=0 AND rp.route_code=?", @route_code)
    @m_customs = @m_customs.select("m_customs.id, m_customs.cust_kbn, m_customs.cust_code, m_customs.cust_name, m_customs.addr_1, m_customs.latitude, m_customs.longitude, m_customs.admin_code, admin.cust_name as admin_name, admin.tel_no as admin_tel, admin.email as admin_email, type.value as type_value, rp.route_code, rp.tree_no, case when (m_customs.start_date is null OR m_customs.start_date<='#{@now_date}') AND (m_customs.end_date is null OR m_customs.end_date>='#{@now_date}') then '' else 'lightgrey' end as bgcolor, '' AS route_memo, 0 AS seq_id")
    @m_customs = @m_customs.order("rp.tree_no, m_customs.cust_code")
    iCount = 0
    @m_customs.each do |m_custom|
      @memo = "|br|"

      @item_kbn = ""
      @rundate_count = 1
      @m_route_rundates = MRouteRundate.joins("left join m_combos week on week.class_1='#{G_WEEK_CLASS_1}' and week.class_2=0 and week.class_code=m_route_rundates.run_week").joins("left join m_combos yobi on yobi.class_1='#{G_YOBI_CLASS_1}' and yobi.class_2=0 and yobi.class_code=m_route_rundates.run_yobi").joins("left join m_combos item on item.class_1='#{G_ITEM_CLASS_1}' and item.class_2=0 and item.class_code=m_route_rundates.item_kbn").where("m_route_rundates.route_code=?", @route_code).select("m_route_rundates.*, week.class_name as week_name, yobi.class_name as yobi_name, item.class_name as item_name").order("m_route_rundates.item_kbn, m_route_rundates.tree_no")
      @m_route_rundates.each do |m_route_rundate|
        if @item_kbn == m_route_rundate.item_kbn.to_s
          @memo = @memo + "、" + m_route_rundate.week_name.to_s + m_route_rundate.yobi_name.to_s
        else
          @item_kbn = m_route_rundate.item_kbn.to_s
          if @rundate_count > 1
            @memo = @memo + "|br|"
          end
          @memo = @memo + m_route_rundate.item_name.to_s + "　" + m_route_rundate.week_name.to_s + m_route_rundate.yobi_name.to_s
        end
        @rundate_count = @rundate_count + 1
      end
      @m_customs[iCount].route_memo = @memo
      iCount = iCount + 1
    end
    
    if @map_zenrin_cid.blank?
      @google_map_display = ""
      @zenrin_map_dispaly = "display:none;"
    else
      @google_map_display = "visibility:hidden;"
      @zenrin_map_dispaly = ""
    end
    
    @def_zoom = 18
    if @m_route_point.nil?
      @def_lat = A_DEF_LATITUDE
      @def_lng = A_DEF_LONGITUDE
    else
      @def_lat = @m_route_point.latitude
      @def_lng = @m_route_point.longitude
    end
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

end
