class MCustomAddController < ApplicationController

  before_action :authenticate_user!
  before_action :set_map_key
  before_action :set_zenrin_map_key
  require 'nkf'

  # GET /m_custom_add
  def index

    @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
    @m_route_areas = MRouteArea.joins("INNER JOIN m_routes r ON r.route_code=m_route_areas.route_code").joins("left join m_combos clr on clr.class_1='#{G_COLOR_PATTERN_CLASS_1}' and clr.class_2=0 and clr.class_code=r.area_color").where("m_route_areas.latlng is not null and r.delete_flg=0").select("m_route_areas.*,r.route_name, clr.value as area_color_value").order("m_route_areas.route_code")
    @m_route_codes = MRoute.where("delete_flg=0").order("id asc").map{|i| [i.route_code.to_s + ':' + i.route_name.to_s, i.route_code] }
    @use_contents = MCombo.where("class_1='#{G_USE_CONTENT_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
    
    if params[:lat_del]
      @def_lat = params[:lat_del]
      @def_lng = params[:lng_del]
      @def_zoom = params[:zoom_del]
    else
      @def_lat = A_DEF_LATITUDE
      @def_lng = A_DEF_LONGITUDE
      @def_zoom = 18
    end
    @def_address = A_DEF_ADDRESS
    render
  end

  # POST /m_custom_add
  def ajax
    if params[:chg_flg_new]
      if params[:chg_flg_new][0]=="2"
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
      elsif params[:chg_flg_new][0]=="3"
        #ステーション番号取得
        @cust_name = params[:cust_name_new][0]
        @cust_name_chg = @cust_name.to_s
        @cust_name_max = 0
        @station_nos = MCustom.where("cust_kbn=? and cust_name like ? and delete_flg=0", G_CUST_KBN_STATION, @cust_name.to_s + "%")
        @station_nos.each do |station_no|
          # 最大値の取得
          @cust_no = NKF.nkf('-m0Z1 -w', station_no.cust_name.split(@cust_name)[1].to_s)
          if @cust_no =~ /\d+/
            if @cust_no.to_i > @cust_name_max
              @cust_name_max = @cust_no.to_i
            end
          end
        end
        if @cust_name_max != 0
          @cust_name_chg = @cust_name.to_s + (@cust_name_max + 1).to_s
        end
        @ajaxflg = 6
      else
        if params[:latitude_new]
          # 重複チェック
          @custom_check = MCustom.where("cust_kbn='#{G_CUST_KBN_STATION}' and cust_name=? and latitude=? and longitude=? and delete_flg=0", params[:cust_name_new][0], params[:latitude_new][0], params[:longitude_new][0]).first
          if @custom_check.nil?

            # 管理者存在チェック
            @admin_check = MCustom.where("cust_kbn='#{G_CUST_KBN_ADMIN}' and cust_code=?",params[:admin_code_new][0]).first
            if not @admin_check.nil? or params[:admin_code_new][0] == ""
              if @admin_check.nil?
                @admin_name = ""
                @admin_tel = ""
                @admin_email = ""
              else
                @admin_name = @admin_check.cust_name
                @admin_tel = @admin_check.tel_no
                @admin_email = @admin_check.email
              end
              # ステーション・収集区登録
              custcode = MCustom.where("cust_kbn='#{G_CUST_KBN_STATION}'").maximum(:cust_code).to_i + 1
              @custcode = "%07d" % custcode
              
              if params[:icon_new].blank?
                icon_new = nil
              else
                icon_new = params[:icon_new][0]
              end
              @m_custom = MCustom.new(:cust_kbn => G_CUST_KBN_STATION, :cust_code => @custcode, :cust_name => params[:cust_name_new][0], :addr_1 => params[:address_new][0], :addr_2 => params[:addr_2_new][0], :latitude => params[:latitude_new][0], :longitude => params[:longitude_new][0], :admin_code => params[:admin_code_new][0], :use_content => params[:use_content_new][0], :shinsei_date => params[:shinsei_date_new][0], :start_date => params[:start_date_new][0], :setai_count => params[:setai_count_new][0], :use_count => params[:use_count_new][0], :memo => params[:memo_new][0], :delete_flg => 0, :last_up_user => current_user.user_id.to_s, :icon => icon_new);
              if @m_custom.save
                if params[:route_new]
                  if not params[:route_new][0].blank?
                    @tree_no = MRoutePoint.where("route_code=?", params[:route_new][0]).maximum(:tree_no).to_i + 1
                    @m_route_point = MRoutePoint.new(:route_code => params[:route_new][0], :tree_no=> @tree_no, :cust_kbn => G_CUST_KBN_STATION, :cust_code => @custcode)
                    @m_route_point.save
                    change_comment = @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
                    api_log_hists(301, 1, change_comment)
                    logger.fatal(current_user.user_id.to_s + "_m_custom_add_add")
                  end
                end
                @ajaxflg = 2
              else
                @ajaxflg = -1
              end
            else
              @ajaxflg = -5
            end
          else
            # 重複していた場合
              @ajaxflg = -2
          end
        end
      end
    end
    #ステーション削除
    if params[:delete_flg]=="1"
      @m_custom = MCustom.find(params[:id])
      @m_custom.update(:delete_flg => 1)
      change_comment = @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
      api_log_hists(301, 3, change_comment)
      logger.fatal(current_user.user_id.to_s + "_m_custom_add_dlt")
      @ajaxflg = 3
    end
    #マーカー再描画
    if params[:marker_flg]
      @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
      routecode = params[:routecode_marker][0]
      northeast_lat = params[:northeast_lat][0]
      southwest_lat = params[:southwest_lat][0]
      northeast_lng = params[:northeast_lng][0]
      southwest_lng = params[:southwest_lng][0]
      
      @m_customs = MCustom.joins("left join m_customs admin ON admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code")
      @m_customs = @m_customs.joins("left join m_combos type on type.class_1='#{G_ADMIN_TYPE_CLASS_1}' and type.class_2=0 and type.class_code=admin.admin_type")
      @m_customs = @m_customs.joins("left join (select min(mr.route_code) as route_code, mrp.cust_kbn, mrp.cust_code from m_routes mr inner join m_route_points mrp on mrp.route_code=mr.route_code where mr.delete_flg=0 and mrp.cust_kbn='#{G_CUST_KBN_STATION}' group by mrp.cust_kbn, mrp.cust_code) mrp on mrp.cust_kbn=m_customs.cust_kbn and mrp.cust_code=m_customs.cust_code")
      @m_customs = @m_customs.joins("left join m_routes mr on mr.route_code=mrp.route_code")
      @m_customs = @m_customs.joins("left join m_combos clr on clr.class_1='#{G_COLOR_PATTERN_CLASS_1}' and clr.class_2=0 and clr.class_code=mr.area_color")
      @m_customs = @m_customs.where("m_customs.delete_flg=0 AND m_customs.cust_kbn='#{G_CUST_KBN_STATION}' AND m_customs.latitude<='#{northeast_lat}' AND m_customs.latitude>='#{southwest_lat}' AND m_customs.longitude<='#{northeast_lng}' AND m_customs.longitude>='#{southwest_lng}'")
      @m_customs = @m_customs.select("m_customs.*, m_customs.admin_code, admin.cust_name as admin_name, admin.tel_no as admin_tel, admin.email as admin_email, type.value as type_value, case when (m_customs.start_date is null OR m_customs.start_date<='#{@now_date}') AND (m_customs.end_date is null OR m_customs.end_date>='#{@now_date}') then '' else 'lightgrey' end as bgcolor, '' AS route_memo, clr.value2 as marker_color, 0 AS seq_id")
      @m_customs = @m_customs.order("m_customs.cust_code")

      iCount = 0
      @m_customs.each do |custom|
        @m_customs[iCount].seq_id = iCount
        iCount = iCount + 1
      end

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
