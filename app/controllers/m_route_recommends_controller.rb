class MRouteRecommendsController < ApplicationController

  before_action :authenticate_user!
  before_action :set_map_key
  before_action :set_zenrin_map_key
  before_action :set_hold_params, only: [:edit]
  before_action :set_search_params, only: [:index, :destroy, :edit]
  
  def index
    routecode = params[:routecode]
    @m_route_recommends = MRouteRecommend.joins("left join t_carruns tc on tc.id=m_route_recommends.carrun_id").where("m_route_recommends.route_code=?", routecode).select("m_route_recommends.*, tc.out_timing").order("m_route_recommends.priority asc, id asc")
    @m_route = MRoute.where("route_code = ?", routecode).first

    @m_route_points = MRoutePoint.joins("INNER JOIN m_customs c ON c.cust_kbn=m_route_points.cust_kbn AND c.cust_code = m_route_points.cust_code").where("m_route_points.route_code=?", routecode).select("c.cust_code, c.cust_name, c.latitude, c.longitude").order("m_route_points.tree_no")
    if @m_route_points.blank?
      @def_lat = A_DEF_LATITUDE
      @def_lng = A_DEF_LONGITUDE
    else
      @def_lat = @m_route_points[0].latitude
      @def_lng = @m_route_points[0].longitude
    end
  end
  
  # POST m_route_recommends
  def edit
    if params[:upd_flg]
      if params[:upd_flg].to_s=="3"
        # トランザクション処理
        begin
          ActiveRecord::Base.transaction do
            @iCount = 0
            params[:cnt_no].to_i.times do |i|
              @m_route_recommend = MRouteRecommend.find(params[:recommend_id][@iCount])
              @iCount = @iCount + 1
              @m_route_recommend.update!(:priority => @iCount)
            end
          end
          change_comment = params[:routecode].to_s + ":" + params[:routename].to_s
          api_log_hists(104, 2, change_comment)
          #redirect_to ({:action => "index", :routecode => params[:routecode]}), notice: '並び順の更新が完了しました。'
          redirect_to m_route_recommends_url.to_s+@search_params.to_s + "&routecode="+params[:routecode].to_s, notice: "並び順の更新が完了しました。"
        rescue => e
          #redirect_to ({:action => "index", :routecode => params[:routecode]}), alert: '※並び順の更新に失敗しました。'
          redirect_to m_route_recommends_url.to_s+@search_params.to_s + "&routecode="+params[:routecode].to_s, alert: "※並び順の更新に失敗しました。"
        end
      elsif params[:upd_flg].to_s=="4"
        # トランザクション処理
        begin
          ActiveRecord::Base.transaction do
            # 緯度経度作成
            @latlng = params[:latlng]
            @latlng = @latlng.strip
            @latlng = @latlng.gsub(',',',lng:')
            @latlng = @latlng.gsub('),lng:','},')
            @latlng = @latlng.gsub('(','{lat:')
            @latlng = @latlng.gsub(')','}')
            @m_route_recommend = MRouteRecommend.find(params[:route_recommend_id])
            @m_route_recommend.update!(:latlng => @latlng)
          end
          #redirect_to ({:action => "index", :routecode => params[:routecode]}), notice: '推奨ルートの補正が完了しました。'
          redirect_to m_route_recommends_url.to_s+@search_params.to_s + "&routecode="+params[:routecode].to_s, notice: "推奨ルートの補正が完了しました。"
        rescue => e
          #redirect_to ({:action => "index", :routecode => params[:routecode]}), alert: '※推奨ルートの補正に失敗しました。'
          redirect_to m_route_recommends_url.to_s+@search_params.to_s + "&routecode="+params[:routecode].to_s, alert: "※推奨ルートの補正に失敗しました。"
        end
      else
        routecode = params[:routecode]
        @route_recommend_id = params[:route_recommend_id]
        @upd_flg = params[:upd_flg]
        
        @m_route_recommend = MRouteRecommend.where("id=?", @route_recommend_id).first
        if @m_route_recommend.nil?
          @latlng = ""
          @latlng_origin = ""
        else
          @latlng = @m_route_recommend.latlng
          @latlng = ERB::Util.url_encode(@latlng)
          @latlng_origin = @m_route_recommend.latlng_origin
          @latlng_origin = ERB::Util.url_encode(@latlng_origin)
        end
        @m_route_points = MRoutePoint.joins("INNER JOIN m_customs c ON c.cust_kbn=m_route_points.cust_kbn AND c.cust_code = m_route_points.cust_code").where("m_route_points.route_code=?", routecode).select("m_route_points.tree_no, c.cust_code, c.cust_name, c.latitude, c.longitude").order("m_route_points.tree_no")
        if @m_route_points.blank?
          @def_lat = A_DEF_LATITUDE
          @def_lng = A_DEF_LONGITUDE
        else
          @def_lat = @m_route_points[0].latitude
          @def_lng = @m_route_points[0].longitude
        end
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
      if params[:route_recommend_id].to_s=="0"
        #最終priority取得
        @priority_max=MRouteRecommend.maximum(:priority, :conditions => {:route_code=> params[:routecode]})
        @priority_max=@priority_max.to_i+1
        @m_route_recommend = MRouteRecommend.new(:route_code => params[:routecode], :priority=> @priority_max, :latlng => @latlng)
        
        routecode = params[:routecode]
        if @m_route_recommend.save
          err_flg=0
        end
      else
        @m_route_recommend = MRouteRecommend.where("id=?", params[:route_recommend_id]).first
        routecode = params[:routecode]
        if @m_route_recommend.update(:latlng => @latlng)
          err_flg=0
        end
      end

      @latlng = @m_route_recommend.latlng
      @latlng = ERB::Util.url_encode(@latlng)

      @latlng_origin = @m_route_recommend.latlng_origin
      @latlng_origin = ERB::Util.url_encode(@latlng_origin)

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
        api_log_hists(104, 2, change_comment)
        flash.now[:notice] = "更新処理が完了しました。"
      else
        flash.now[:alert] = "更新処理に失敗しました。"
      end
    end
  end
  
  # DELETE /m_route_recommend/1
  def destroy
    # トランザクション処理
    begin
      ActiveRecord::Base.transaction do
        @recommend = MRouteRecommend.find(params[:id])
        @recommend.destroy
        #既存の優先順位変更
        @priority_count = 1
        @m_route_recommends = MRouteRecommend.where("route_code=?", params[:routecode]).order("priority asc")
        @m_route_recommends.each do |route_recommend|
          m_route_recommend = MRouteRecommend.find(route_recommend.id)
          m_route_recommend.update(:priority => @priority_count)
          @priority_count = @priority_count + 1
        end
      end
      @m_route = MRoute.where("route_code=?", params[:routecode]).first
      change_comment = @m_route.route_code.to_s + ":" + @m_route.route_name.to_s
      api_log_hists(104, 3, change_comment)
      redirect_to m_route_recommends_url.to_s+@search_params.to_s + "&routecode="+params[:routecode].to_s, notice: "推奨ルートの削除が完了しました。"
    rescue => e
      redirect_to m_route_recommends_url.to_s+@search_params.to_s + "&routecode="+params[:routecode].to_s, alert: "※推奨ルートの削除に失敗しました。"
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
