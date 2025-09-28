class MRouteRoadsController < ApplicationController

  before_action :authenticate_user!
  before_action :set_map_key
  before_action :set_zenrin_map_key
  
  # GET /m_route_recommends
  def index
  
    @m_route_recommend = MRouteRecommend.joins("left join t_carruns tc on tc.id=m_route_recommends.carrun_id").where("m_route_recommends.id=?", params[:recommend_id]).select("m_route_recommends.*, tc.out_timing").first
    @m_route = MRoute.where("route_code = ?", @m_route_recommend.route_code.to_s).first

    @m_route_points = MRoutePoint.joins("INNER JOIN m_customs c ON c.cust_kbn=m_route_points.cust_kbn AND c.cust_code = m_route_points.cust_code").where("m_route_points.route_code=?", @m_route_recommend.route_code.to_s).select("m_route_points.tree_no, c.cust_code, c.cust_name, c.latitude, c.longitude").order("m_route_points.tree_no")
    if @m_route_points.blank?
      @def_lat = A_DEF_LATITUDE
      @def_lng = A_DEF_LONGITUDE
    else
      @def_lat = @m_route_points[0].latitude
      @def_lng = @m_route_points[0].longitude
    end

    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
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
