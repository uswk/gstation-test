class MRouteAreasController < ApplicationController

  before_action :authenticate_user!
  before_action :set_map_key
  before_action :set_zenrin_map_key

  before_action :set_hold_params, only: [:edit]
  before_action :set_search_params, only: [:index, :destroy]

  def index
    routecode = params[:routecode]
    @m_route_areas = MRouteArea.where("route_code=?", routecode).order("tree_no")
    @m_route = MRoute.joins("left join m_combos mc on mc.class_1='#{G_COLOR_PATTERN_CLASS_1}' and mc.class_2=0 and mc.class_code=m_routes.area_color").where("route_code = ?", routecode).select("m_routes.*, mc.value as area_color_value").first

    @m_route_points = MRoutePoint.joins("INNER JOIN m_customs c ON c.cust_kbn=m_route_points.cust_kbn AND c.cust_code = m_route_points.cust_code").where("m_route_points.route_code=?", routecode).select("c.cust_code, c.cust_name, c.latitude, c.longitude").order("m_route_points.tree_no")
    if @m_route_points.blank?
      @def_lat = A_DEF_LATITUDE
      @def_lng = A_DEF_LONGITUDE
    else
      @def_lat = @m_route_points[0].latitude
      @def_lng = @m_route_points[0].longitude
    end
  end
  
  def edit
    if params[:upd_flg]
      routecode = params[:routecode]
      @tree_no = params[:tree_no]
      @upd_flg = params[:upd_flg]

      @m_route_area = MRouteArea.where("route_code=? and tree_no=?", routecode, @tree_no).first
      if @m_route_area.nil?
        @latlng = ""
      else
        @latlng = @m_route_area.latlng
        @latlng = ERB::Util.url_encode(@latlng)
      end

      @m_route_point = MRoutePoint.joins("INNER JOIN m_customs c ON c.cust_kbn=m_route_points.cust_kbn AND c.cust_code = m_route_points.cust_code").where("m_route_points.route_code=?", routecode).select("c.latitude, c.longitude").order("m_route_points.tree_no").first
      if @m_route_point.nil?
        @def_lat = A_DEF_LATITUDE
        @def_lng = A_DEF_LONGITUDE
      else
        @def_lat = @m_route_point.latitude
        @def_lng = @m_route_point.longitude
      end
    else
      # 緯度経度作成
      @latlng = params[:latlng]
      @latlng = @latlng.strip
      @latlng = @latlng.gsub(',',',lng:')
      @latlng = @latlng.gsub('),lng:','},')
      @latlng = @latlng.gsub('(','{lat:')
      @latlng = @latlng.gsub(')','}')
      
      # 更新処理
      err_flg=1
      if params[:upd_flg2]=="1"
        #最終tree_no取得
        @tree_no_max=MRouteArea.where(:route_code=> params[:routecode]).maximum(:tree_no)
        @tree_no_max=@tree_no_max.to_i+1
        @m_route_area_upd = MRouteArea.new(:route_code => params[:routecode], :tree_no=> @tree_no_max, :latlng => @latlng)
        
        routecode = params[:routecode]
        @upd_flg = 2
        @tree_no = @tree_no_max
        if @m_route_area_upd.save
          err_flg=0
        end
      else
        @m_route_area = MRouteArea.where("route_code=? and tree_no=?", params[:routecode], params[:tree_no]).first
        routecode = params[:routecode]
        @upd_flg = 2
        @tree_no = params[:tree_no]
        if @m_route_area.update(:latlng => @latlng)
          err_flg=0
        end
      end

      @m_route_area = MRouteArea.where("route_code=? and tree_no=?", routecode, @tree_no).first
      if @m_route_area.nil?
        @latlng = ""
      else
        @latlng = @m_route_area.latlng
        @latlng = ERB::Util.url_encode(@latlng)
      end

      @m_route_point = MRoutePoint.joins("INNER JOIN m_customs c ON c.cust_kbn=m_route_points.cust_kbn AND c.cust_code = m_route_points.cust_code").where("m_route_points.route_code=?", routecode).select("c.latitude, c.longitude").order("m_route_points.tree_no").first
      if @m_route_point.nil?
        @def_lat = A_DEF_LATITUDE
        @def_lng = A_DEF_LONGITUDE
      else
        @def_lat = @m_route_point.latitude
        @def_lng = @m_route_point.longitude
      end
      if err_flg==0
        @m_route = MRoute.where("route_code=?", routecode).first
        change_comment = @m_route.route_code.to_s + ":" + @m_route.route_name.to_s
        api_log_hists(102, 2, change_comment)
        logger.fatal(current_user.user_id.to_s + "_m_route_areas_upd")
        flash.now[:notice] = "更新処理が完了しました。"
      else
        flash.now[:alert] = "更新処理に失敗しました。"
      end
    end
  end
  
  # DELETE /m_route_areas/1
  def destroy
    @m_route_area = MRouteArea.find(params[:id])
    @m_route = MRoute.where("route_code=?", @m_route_area.route_code).first
    @m_route_area.destroy
    respond_to do |format|
      change_comment = @m_route.route_code.to_s + ":" + @m_route.route_name.to_s
      api_log_hists(102, 3, change_comment)
      logger.fatal(current_user.user_id.to_s + "_m_route_areas_dlt")
      format.html { redirect_to m_route_areas_url.to_s+@search_params.to_s + "&routecode="+params[:routecode].to_s, notice: "削除作業が完了しました。" }
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

    def set_hold_params
      @search_page = params[:search_page]
      @search_routecode = params[:search_routecode]
      @search_routename = params[:search_routename]
      @search_itaku = params[:search_itaku]
      @search_delete = params[:search_delete]
    end

    def set_search_params
      @search_param = ""
      if not params[:hold_params].blank?
        @search_params = @search_params.to_s + "hold_params=" + params[:hold_params]
        @search_params = @search_params.to_s + "&search_routecode=" + ERB::Util.url_encode(params[:search_routecode])
        @search_params = @search_params.to_s + "&search_routename=" + ERB::Util.url_encode(params[:search_routename])
        @search_params = @search_params.to_s + "&search_itaku=" + ERB::Util.url_encode(params[:search_itaku])
        @search_params = @search_params.to_s + "&search_delete=" + params[:search_delete]
        if not params[:search_page].blank?
          @search_params = @search_params.to_s + "&search_page=" + params[:search_page]
          @search_params = @search_params.to_s + "&page=" + params[:search_page]
        end
      end
      if !@search_params.blank?
        @search_params = "?" + @search_params.to_s
      end
    end
end
