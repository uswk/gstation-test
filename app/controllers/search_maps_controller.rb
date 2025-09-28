class SearchMapsController < ApplicationController
  protect_from_forgery with: :null_session

  before_action :authenticate_user!
  before_action :set_map_key
  before_action :set_zenrin_map_key

  # GET /search_maps
  def index

    @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
    @m_route_areas = MRouteArea.joins("INNER JOIN m_routes r ON r.route_code=m_route_areas.route_code").joins("left join m_combos clr on clr.class_1='#{G_COLOR_PATTERN_CLASS_1}' and clr.class_2=0 and clr.class_code=r.area_color").where("m_route_areas.latlng is not null and r.delete_flg=0").select("m_route_areas.*,r.route_name, clr.value as area_color_value").order("m_route_areas.route_code")
    @m_route_codes = MRoute.where("delete_flg=0").order("route_code asc").map{|i| [i.route_name, i.route_code] }
    @admin_types = MCombo.where("class_1=? and class_2=0 and delete_flg=0", G_ADMIN_TYPE_CLASS_1).order("class_code")
    @use_contents = MCombo.where("class_1='#{G_USE_CONTENT_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
    
    if params[:lat_map]
      @def_lat = params[:lat_map]
      @def_lng = params[:lng_map]
      @def_zoom = params[:zoom_map]
    else
      @def_lat = A_DEF_LATITUDE
      @def_lng = A_DEF_LONGITUDE
      @def_zoom = 18
    end
    @def_address = A_DEF_ADDRESS
    render
  end

  # GET /search_maps/1
  def show
    @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
    id_array = params[:id].split("_")
    
    @output_kbn = id_array[0]
    @zoom = id_array[1]
    @center_lat = id_array[2].gsub("-", ".")
    @center_lng = id_array[3].gsub("-", ".")
    northeast_lat = id_array[4].gsub("-", ".")
    southwest_lat = id_array[5].gsub("-", ".")
    northeast_lng = id_array[6].gsub("-", ".")
    southwest_lng = id_array[7].gsub("-", ".")
    @maptype = id_array[8]
    
    # 選択条件
    if @output_kbn.to_s=="1"
      strwhere = "m_customs.delete_flg=0 AND m_customs.cust_kbn='#{G_CUST_KBN_STATION}' AND m_customs.latitude<='#{northeast_lat}' AND m_customs.latitude>='#{southwest_lat}' AND m_customs.longitude<='#{northeast_lng}' AND m_customs.longitude>='#{southwest_lng}' AND (m_customs.start_date is null OR m_customs.start_date<='#{@now_date}') AND (m_customs.end_date is null OR m_customs.end_date>='#{@now_date}')"
      # 管理種別条件
      typewhere = ""
      if id_array[9].to_s=="1"
        if not typewhere.blank?
          typewhere = typewhere + " or "
        end
        typewhere = typewhere + " admin.admin_type is null"
      end
      @iCount = 9
      @admin_types = MCombo.where("class_1=? and class_2=0 and delete_flg=0", G_ADMIN_TYPE_CLASS_1).order("class_code")
      @admin_types.each do |admin_type|
        if id_array[@iCount]=="1"
          if not typewhere.blank?
            typewhere = typewhere + " or "
          end
          typewhere = typewhere + " admin.admin_type = " + admin_type.class_code.to_s
        end
        @iCount = @iCount + 1
      end
      if not typewhere.blank?
        typewhere = " and (" + typewhere + ")"
      else
        typewhere = " and (1=2)"
      end
    
      strwhere = strwhere + typewhere
    else
      strwhere = "m_customs.cust_kbn='#{G_CUST_KBN_STATION}' AND m_customs.cust_code='#{id_array[9].to_s}'"
    end
    @m_customs = MCustom.joins("LEFT JOIN m_customs admin ON admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code").where("#{strwhere}").select("m_customs.*, admin.cust_name as admin_name, admin.tel_no as admin_tel, admin.email as admin_email").order("m_customs.cust_code")
    @marker = ""
    @iCount = 1
    @m_customs.each do |m_custom|
      @marker = @marker + "&markers=label:" + @iCount.to_s + "|" + m_custom.latitude.to_s + "," + m_custom.longitude.to_s
      @iCount = @iCount + 1
    end

    respond_to do |format|
      format.html { redirect_to search_map_path(format: :pdf)}
      format.pdf do
        render pdf: 'show',
             encoding: 'UTF-8',
             layout: 'pdf',
             show_as_html: params[:debug].present?
             api_log_hists(1601, 5, "")
      end
    end
  end

  # POST /m_custom_add
  def ajax
    #マーカー再描画
    if params[:marker_flg]
      @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
      routecode = params[:routecode_marker][0]
      northeast_lat = params[:northeast_lat][0]
      southwest_lat = params[:southwest_lat][0]
      northeast_lng = params[:northeast_lng][0]
      southwest_lng = params[:southwest_lng][0]
      
      # 選択条件
      strwhere = "m_customs.delete_flg=0 AND m_customs.cust_kbn='#{G_CUST_KBN_STATION}' AND m_customs.latitude<='#{northeast_lat}' AND m_customs.latitude>='#{southwest_lat}' AND m_customs.longitude<='#{northeast_lng}' AND m_customs.longitude>='#{southwest_lng}' AND (m_customs.start_date is null OR m_customs.start_date<='#{@now_date}') AND (m_customs.end_date is null OR m_customs.end_date>='#{@now_date}')"
      # 管理者種別条件
      typewhere = ""
      if params[:admin_type]["-1"]=="1"
        if not typewhere.blank?
          typewhere = typewhere + " or "
        end
        typewhere = typewhere + " admin.admin_type is null"
      end
      @admin_types = MCombo.where("class_1=? and class_2=0 and delete_flg=0", G_ADMIN_TYPE_CLASS_1).order("class_code")
      @admin_types.each do |admin_type|
        if params[:admin_type][admin_type.class_code.to_s]=="1"
          if not typewhere.blank?
            typewhere = typewhere + " or "
          end
          typewhere = typewhere + " admin.admin_type = " + admin_type.class_code.to_s
        end
      end
      if not typewhere.blank?
        typewhere = " and (" + typewhere + ")"
      else
        typewhere = " and (1=2)"
      end
      strwhere = strwhere + typewhere
      @m_customs = MCustom.joins("LEFT JOIN m_customs admin ON admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code")
      @m_customs = @m_customs.joins("left join m_combos type on type.class_1='#{G_ADMIN_TYPE_CLASS_1}' and type.class_2=0 and type.class_code=admin.admin_type")
      @m_customs = @m_customs.joins("left join (select min(mr.route_code) as route_code, mrp.cust_kbn, mrp.cust_code from m_routes mr inner join m_route_points mrp on mrp.route_code=mr.route_code where mr.delete_flg=0 and mrp.cust_kbn='#{G_CUST_KBN_STATION}' group by mrp.cust_kbn, mrp.cust_code) mrp on mrp.cust_kbn=m_customs.cust_kbn and mrp.cust_code=m_customs.cust_code")
      @m_customs = @m_customs.joins("left join m_routes mr on mr.route_code=mrp.route_code")
      @m_customs = @m_customs.joins("left join m_combos clr on clr.class_1='#{G_COLOR_PATTERN_CLASS_1}' and clr.class_2=0 and clr.class_code=mr.area_color")
      @m_customs = @m_customs.where("#{strwhere}")
      @m_customs = @m_customs.select("m_customs.*, admin.cust_name as admin_name, admin.tel_no as admin_tel, admin.email as admin_email, type.value as type_value, '' as route_memo, clr.value2 as marker_color")
      @m_customs = @m_customs.order("m_customs.cust_code")
      
      @ajaxflg = 4
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
    if not current_user.nil?
      @map_zenrin = MCombo.where("class_1=? AND class_name=?", G_ZENRIN_CLASS_1, current_user.user_id).first
      if not @map_zenrin.nil?
        @map_zenrin_cid = @map_zenrin.value.to_s
        @map_zenrin_uid = @map_zenrin.value2.to_s
        @map_zenrin_pwd = @map_zenrin.value3.to_s
      end
    end
  end

end
