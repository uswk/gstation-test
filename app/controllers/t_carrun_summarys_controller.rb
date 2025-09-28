class TCarrunSummarysController < ApplicationController
 
  before_action :authenticate_user!
  before_action :set_map_key
  before_action :set_zenrin_map_key
  before_action :set_itaku, :only => [:index]
  before_action :set_use_contents, :only => [:show]
  before_action :set_search_params, only: [:index, :create]
  require 'nkf'

  # GET /t_carrun_summarys
  def index
    if params[:hold_params].blank?
      @routecode = params[:search].blank? ? "" : params[:search][:route]
      @itakucode = params[:search].blank? ? "" : params[:search][:itaku]
      @outdate_from = params[:search].blank? ? Date.today.try(:strftime, "%Y/%m/%d") : params[:search][:date_from]
      @outdate_to = params[:search].blank? ? Date.today.try(:strftime, "%Y/%m/%d") : params[:search][:date_to]
    else
      @routecode = params[:routecode].blank? ? "" : params[:routecode]
      @itakucode = params[:itakucode].blank? ? "" : params[:itakucode]
      @outdate_from = params[:outdate_from].blank? ? Date.today.try(:strftime, "%Y/%m/%d") : params[:outdate_from]
      @outdate_to = params[:outdate_to].blank? ? Date.today.try(:strftime, "%Y/%m/%d") : params[:outdate_to]
    end
    strwhere = "1=1"
    if @outdate_from != ""
      strwhere = strwhere + " AND t_carruns.out_timing>='#{@outdate_from}'"
    end
    if @outdate_to != ""
      @outdate_tom = @outdate_to.to_date+1
      strwhere = strwhere + " AND t_carruns.out_timing<'#{@outdate_tom}'"
    end
    if @routecode != ""
      strwhere = strwhere + " AND t_carruns.route_code = '#{@routecode}'"
    end
    if not current_user.itaku_code.blank?
      strwhere = strwhere + " AND m_cars.itaku_code='#{current_user.itaku_code}'"
    else
      if @itakucode != ""
        strwhere = strwhere + " AND m_cars.itaku_code='#{@itakucode}'"
      end
    end
    @t_carruns = TCarrun.joins("LEFT JOIN m_cars ON m_cars.car_code=t_carruns.car_code")
    @t_carruns = @t_carruns.joins("LEFT JOIN m_routes ON m_routes.route_code=t_carruns.route_code")
    @t_carruns = @t_carruns.joins("left join m_customs itaku ON itaku.cust_kbn='#{G_CUST_KBN_GYOSHA}' and itaku.cust_code=m_cars.itaku_code")
    @t_carruns = @t_carruns.select("t_carruns.id, min(t_carruns.out_timing) as out_timing, t_carruns.car_code, t_carruns.route_code, case when max(ifnull(t_carruns.in_timing,'2200-12-31'))='2200-12-31' then null else max(t_carruns.in_timing) end as in_timing, m_cars.car_reg_code, m_routes.route_name, itaku.cust_name as itaku_name")
    @t_carruns = @t_carruns.where("#{strwhere}")
    @t_carruns = @t_carruns.group("DATE_FORMAT(t_carruns.out_timing, '%Y%m%d'), t_carruns.car_code, t_carruns.route_code")
    @t_carrun_count = @t_carruns.length
    @t_carruns = @t_carruns.order("t_carruns.out_timing desc, t_carruns.id desc")
    @t_carruns = @t_carruns.page(params[:page]).per("#{G_DEF_PAGE_PER}")

    # group by時にkaminariの不具合？の為強制的にページング処理
    @limit = TCarrun.limit(@t_carrun_count).last
    @limitid = @limit.nil? ? 0 : @limit.id
    @limits = TCarrun.where("id<=?", @limitid).page(params[:page]).per("#{G_DEF_PAGE_PER}")

    # 収集区
    if current_user.itaku_code.blank?
      routewhere = "m_routes.delete_flg = 0"
    else
      routewhere = "m_routes.delete_flg = 0 and mrr.itaku_code = '#{current_user.itaku_code}'"
    end
    @route_codes = MRoute.joins("left join m_route_rundates mrr on mrr.route_code=m_routes.route_code")
    @route_codes = @route_codes.where("#{routewhere}").group("m_routes.route_code, m_routes.route_name").order("m_routes.route_code asc").map{|i| [i.route_code.to_s + ':' + i.route_name.to_s, i.route_code] }
    
    #@fee_gass_flg = A_DEF_FEE_GASS_FLG
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /t_carrun_summarys/1
  def show
    @now_date = params[:out_date].to_date.strftime("%Y/%m/%d")
    @tom_date = params[:out_date].to_date.tomorrow.strftime("%Y/%m/%d")
    @car_code = params[:car_code]
    @route_code = params[:route_code]
    @carrun_id = params[:id]
    
    # 収集区
    if current_user.itaku_code.blank?
      routewhere = "m_routes.delete_flg = 0"
    else
      routewhere = "m_routes.delete_flg = 0 and mrr.itaku_code = '#{current_user.itaku_code}'"
    end
    @route_codes = MRoute.joins("left join m_route_rundates mrr on mrr.route_code=m_routes.route_code")
    @route_codes = @route_codes.where("#{routewhere}").group("m_routes.route_code, m_routes.route_name").order("m_routes.route_code asc").map{|i| [i.route_code.to_s + ':' + i.route_name.to_s, i.route_code] }
    
    #見出用
    @t_carrun = TCarrun.joins("LEFT JOIN m_cars ON m_cars.car_code=t_carruns.car_code")
    @t_carrun = @t_carrun.joins("LEFT JOIN m_drivers md ON md.driver_code=t_carruns.driver_code")
    @t_carrun = @t_carrun.joins("LEFT JOIN m_drivers smd1 ON smd1.driver_code=t_carruns.sub_driver_code1")
    @t_carrun = @t_carrun.joins("LEFT JOIN m_drivers smd2 ON smd2.driver_code=t_carruns.sub_driver_code2")
    @t_carrun = @t_carrun.joins("LEFT JOIN m_routes ON m_routes.route_code=t_carruns.route_code")
    @t_carrun = @t_carrun.joins("left join m_customs itaku ON itaku.cust_kbn='#{G_CUST_KBN_GYOSHA}' and itaku.cust_code=m_cars.itaku_code")
    @t_carrun = @t_carrun.joins("LEFT JOIN t_fee_gasses tfg ON tfg.out_timing=t_carruns.out_timing and tfg.car_code=t_carruns.car_code")
    @t_carrun = @t_carrun.select("t_carruns.id, min(t_carruns.out_timing) as out_timing, max(t_carruns.out_timing) as max_out_timing, t_carruns.car_code, t_carruns.driver_code, t_carruns.sub_driver_code1, t_carruns.sub_driver_code2, t_carruns.route_code, case when max(ifnull(t_carruns.in_timing,'2200-12-31'))='2200-12-31' then null else max(t_carruns.in_timing) end as in_timing, max(t_carruns.use_item_flg) as use_item_flg, sum(t_carruns.run_distance) as run_distance, min(t_carruns.mater_out) as mater_out, max(t_carruns.mater_in) as mater_in, m_cars.car_reg_code, md.driver_name, smd1.driver_name as sub_driver_name1, smd2.driver_name as sub_driver_name2, m_routes.route_name, m_routes.route_name, itaku.cust_name as itaku_name, sum(tfg.quantity) as quantity")
    @t_carrun = @t_carrun.where("t_carruns.out_timing>=? and t_carruns.out_timing<? and t_carruns.car_code=? and t_carruns.route_code=?",@now_date, @tom_date, @car_code, @route_code)
    @t_carrun = @t_carrun.group("DATE_FORMAT(t_carruns.out_timing, '%Y%m%d'), t_carruns.car_code, t_carruns.route_code").first
    
    iCount = 0
    #一覧・マーカー用
    @t_collect_lists = TCollectList.joins("INNER JOIN t_carruns tc on tc.out_timing=t_collect_lists.out_timing and tc.car_code=t_collect_lists.car_code")
    @t_collect_lists = @t_collect_lists.joins("left join m_customs mc on mc.cust_kbn=t_collect_lists.cust_kbn and mc.cust_code=t_collect_lists.cust_code")
    @t_collect_lists = @t_collect_lists.joins("left join m_customs mc2 ON mc2.cust_kbn='#{G_CUST_KBN_ADMIN}' AND mc2.cust_code=mc.admin_code")
    @t_collect_lists = @t_collect_lists.joins("left join m_combos ON m_combos.class_1 = '#{G_MIKAISHU_CLASS_1}' AND m_combos.class_2=0 AND m_combos.class_code = t_collect_lists.mikaishu_code")
    @t_collect_lists = @t_collect_lists.joins("left join (select carrun_id, cust_kbn, cust_code, count(*) as memo_count from t_carrun_memos group by carrun_id, cust_kbn, cust_code) tcm on tcm.carrun_id=tc.id and tcm.cust_kbn=t_collect_lists.cust_kbn and tcm.cust_code=t_collect_lists.cust_code")
    @t_collect_lists = @t_collect_lists.joins("left join (select tcl.cust_kbn, tcl.cust_code from t_collect_lists tcl inner join t_carruns tc on tc.out_timing=tcl.out_timing and tc.car_code=tcl.car_code where tcl.out_timing>='#{@now_date}' and tcl.out_timing<'#{@tom_date}' and tc.route_code='#{@route_code}' and tcl.cust_code<>'*' and tcl.finish_timing is not null group by tcl.cust_kbn, tcl.cust_code) acl on acl.cust_kbn=t_collect_lists.cust_kbn and acl.cust_code=t_collect_lists.cust_code")

    #廃棄物数量入力時
    @iCount = 0
    @strselect = ""

    @t_collect_details = TCollectDetail.joins("inner join t_collect_lists tcl on tcl.out_timing=t_collect_details.out_timing and tcl.car_code=t_collect_details.car_code and tcl.spot_no=t_collect_details.spot_no")
    @t_collect_details = @t_collect_details.joins("inner join t_carruns tc on tc.out_timing=tcl.out_timing and tc.car_code=tcl.car_code")
    @t_collect_details = @t_collect_details.joins("left join m_combos item on item.class_1='#{G_ITEM_CLASS_1}' and item.class_code=t_collect_details.item_kbn")
    @t_collect_details = @t_collect_details.joins("left join m_combos unit on unit.class_1='#{G_UNIT_CLASS_1}' and unit.class_code=t_collect_details.unit_kbn")
    @t_collect_details = @t_collect_details.select("t_collect_details.item_kbn, t_collect_details.unit_kbn, item.class_name as item_name, unit.class_name as unit_name")
    @t_collect_details = @t_collect_details.where("t_collect_details.out_timing>=? and t_collect_details.out_timing<? and t_collect_details.car_code=? and tc.route_code=? and tcl.finish_timing is not null", @now_date, @tom_date, @car_code, @route_code).group("t_collect_details.item_kbn").order("t_collect_details.item_kbn")
    @t_collect_details.each do |t_collect_detail|
      @iCount = @iCount + 1
      @strselect = @strselect + ", '" + t_collect_detail.item_kbn.to_s + "' as item_kbn_" + @iCount.to_s
      @strselect = @strselect + ", '" + t_collect_detail.unit_kbn.to_s + "' as unit_kbn_" + @iCount.to_s
      @strselect = @strselect + ", '" + t_collect_detail.item_name.to_s + "' as item_name_" + @iCount.to_s
      @strselect = @strselect + ", '" + t_collect_detail.unit_name.to_s + "' as unit_name_" + @iCount.to_s
      @strselect = @strselect + ", sum(case when t_collect_lists.cust_kbn='#{G_CUST_KBN_UNLOAD}' then tcd" + @iCount.to_s + ".item_count*-1 else tcd" + @iCount.to_s + ".item_count end) as item_count_" + @iCount.to_s
      @strselect = @strselect + ", " + @iCount.to_s + " as iCount"
      @t_collect_lists = @t_collect_lists.joins("left join t_collect_details tcd" + @iCount.to_s + " on tcd" + @iCount.to_s + ".out_timing=t_collect_lists.out_timing and tcd" + @iCount.to_s + ".car_code=t_collect_lists.car_code and tcd" + @iCount.to_s + ".spot_no=t_collect_lists.spot_no and tcd" + @iCount.to_s + ".item_kbn=" + t_collect_detail.item_kbn.to_s)
    end

    @t_collect_lists = @t_collect_lists.where("t_collect_lists.out_timing >= ? and t_collect_lists.out_timing < ? and t_collect_lists.car_code = ? and tc.route_code=?", @now_date, @tom_date, @car_code, @route_code)
    @t_collect_lists = @t_collect_lists.group("t_collect_lists.cust_kbn, t_collect_lists.cust_code, t_collect_lists.finish_timing")
    @t_collect_lists = @t_collect_lists.joins("left join (select tcl.cust_kbn, tcl.cust_code, count(*) as cust_count from t_collect_lists tcl inner join t_carruns tc on tc.out_timing=tcl.out_timing and tc.car_code=tcl.car_code where tc.out_timing>='#{@now_date}' and tc.out_timing<'#{@tom_date}' and tc.car_code='#{@car_code}' and tc.route_code='#{@route_code}' and tcl.finish_timing is not null group by tcl.cust_kbn, tcl.cust_code) cnt on cnt.cust_kbn=t_collect_lists.cust_kbn and cnt.cust_code=t_collect_lists.cust_code")
    @t_collect_lists = @t_collect_lists.where("t_collect_lists.finish_timing is not null or (t_collect_lists.finish_timing is null and cnt.cust_count is null)")
    @t_collect_lists = @t_collect_lists.select("t_collect_lists.cust_kbn, t_collect_lists.cust_code, t_collect_lists.finish_timing, t_collect_lists.mikaishu_count, t_collect_lists.mikaishu_code, tc.id as carrun_id, tc.out_timing, tc.in_timing, m_combos.class_name as mikaishu_name, t_collect_lists.spot_no, t_collect_lists.spot_no as tree_no, t_collect_lists.cust_name, t_collect_lists.latitude, t_collect_lists.longitude, mc.addr_1, mc.addr_2, mc2.cust_name as admin_name, mc2.tel_no, mc2.email, '' as memo, case when tcm.memo_count is null then 0 else tcm.memo_count end as memo_count, case when acl.cust_code is null then 0 else 1 end as another_collect, case when mc.id is null then 'lightgreen' else case when (mc.start_date is null OR mc.start_date<='#{@now_date}') AND (mc.end_date is null OR mc.end_date>='#{@now_date}') then '' else 'lightgrey' end end as bgcolor, cnt.cust_count, 0 as rank, mc.id as custom_id"+@strselect.to_s)
    @t_collect_lists = @t_collect_lists.order("t_collect_lists.spot_no, t_collect_lists.id")
    @t_collect_lists.each do |collect_list|
      # 写真・メモ情報取得
      if collect_list.memo_count > 0
        memo = ""
        @t_carrun_memos = TCarrunMemo.where("(cust_code<>'*' and (carrun_id=? and cust_kbn=? and cust_code=?) or (finish_timing=? and cust_kbn=? and cust_code=?)) or (cust_code='*' and carrun_id=? and finish_timing=?)", collect_list.carrun_id, collect_list.cust_kbn, collect_list.cust_code, collect_list.finish_timing, collect_list.cust_kbn, collect_list.cust_code, collect_list.carrun_id, collect_list.finish_timing).order("id")
        @t_carrun_memos.each do |carrun_memo|
          memo = memo + "<a href='" + carrun_memo.memo.url(:original).to_s + "' rel='lightbox'><img src='" + carrun_memo.memo.url(:thumb).to_s + "'></a>&nbsp;"
        end
        @t_collect_lists[iCount].memo = memo
      end
      @t_collect_lists[iCount].rank = iCount + 1
      iCount = iCount + 1
    end
    
    if @t_carrun.in_timing.nil?
      # 帰庫時間が入っていなかったら車両情報も表示
      #@t_carrun_lists = TCarrunList.all(:select => "t_carrun_lists.*,mc.car_reg_code, 0 as spot_no",
      #     :joins =>"LEFT JOIN m_cars as mc ON mc.car_code=t_carrun_lists.car_code",
      #     :conditions => ["t_carrun_lists.car_code =? and t_carrun_lists.tree_no = 0 and t_carrun_lists.latitude is not null and t_carrun_lists.longitude is not null", @car_code],
      #     :order => "t_carrun_lists.work_timing desc",
      #     :limit => 1)
      #@carcount = @t_carrun_lists.count
      @t_carrun_lists = TTrack.all(:select => "t_tracks.latitude, t_tracks.longitude, t_tracks.time as work_timing, null as address, mc.car_reg_code, 0 as spot_no",
           :joins =>"LEFT JOIN m_cars as mc ON mc.car_code=t_tracks.car_code",
           :conditions => ["t_tracks.out_timing=? and t_tracks.car_code =? and t_tracks.latitude is not null and t_tracks.longitude is not null", @t_carrun.max_out_timing, @car_code],
           :group => "t_tracks.time, t_tracks.out_timing, t_tracks.car_code, t_tracks.latitude, t_tracks.longitude",
           :order => "t_tracks.time desc, t_tracks.id desc",
           :limit => 1)
      @carcount = 1
    else
      @carcount = 0
    end

    @track_latlng = ""
    @tracks2 = TTrack.joins("INNER JOIN t_carruns tc on tc.out_timing=t_tracks.out_timing and tc.car_code=t_tracks.car_code")
    @tracks2 =@tracks2.where("t_tracks.out_timing>=? and t_tracks.out_timing<? and t_tracks.car_code=? and tc.route_code=? and t_tracks.latitude is not null and t_tracks.longitude is not null", @now_date, @tom_date, @car_code, @route_code).select("t_tracks.out_timing, t_tracks.car_code, group_concat(DISTINCT CONCAT('{lat:',t_tracks.latitude,',lng:',t_tracks.longitude,',time:',DATE_FORMAT(t_tracks.time,'%Y%m%d%H%i%S'),'}') ORDER BY t_tracks.out_timing, t_tracks.car_code, t_tracks.time, t_tracks.id SEPARATOR ',') as latlng").group("t_tracks.car_code")
    @tracks2.each do |track2|
      @track_latlng = track2.latlng.to_s
    end
    @track_latlng = ERB::Util.url_encode(@track_latlng)

    @def_lat = A_DEF_LATITUDE
    @def_lng = A_DEF_LONGITUDE
    
    if not @t_collect_lists.blank?
      @def_lat = @t_collect_lists[0].latitude
      @def_lng = @t_collect_lists[0].longitude
    else
      #軌跡データがあるか確認
      @track = TTrack.joins("INNER JOIN t_carruns tc on tc.out_timing=t_tracks.out_timing and tc.car_code=t_tracks.car_code")
      @track = @track.where("t_tracks.out_timing>=? and t_tracks.out_timing<? and t_tracks.car_code=? and tc.route_code=? and t_tracks.latitude is not null and t_tracks.longitude is not null", @now_date, @tom_date, @car_code, @route_code).first
      if not @track.blank?
        @def_lat = @track.latitude
        @def_lng = @track.longitude
      end
    end

    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
  # POST /t_carrun_summarys
  def create
    if params[:route_recommend_flg].to_s=="1"
      #推奨ルート設定
      
      # トランザクション処理
      begin
        ActiveRecord::Base.transaction do
          @track_latlng = ""
          @track_lat = ""
          @track_lng = ""
          @t_carrun = TCarrun.find(params[:carrun_id])
          @tracks = TTrack.joins("INNER JOIN t_carruns tc on tc.out_timing=t_tracks.out_timing and tc.car_code=t_tracks.car_code").where("t_tracks.out_timing>=? and t_tracks.out_timing<? and t_tracks.car_code=? and tc.route_code=? and t_tracks.latitude is not null and t_tracks.longitude is not null", params[:out_timing_str], params[:out_timing_end], params[:car_code],@t_carrun.route_code).select("t_tracks.*").group("t_tracks.time, t_tracks.out_timing, t_tracks.car_code, t_tracks.latitude, t_tracks.longitude").order("t_tracks.out_timing, t_tracks.car_code, t_tracks.time, t_tracks.id")
          @tracks.each do |track|
            if @track_lat!=track.latitude.to_s || @track_lng!=track.longitude.to_s
              if @track_latlng != ""
                @track_latlng = @track_latlng + ","
              end
              @track_latlng = @track_latlng.to_s + "{lat:" + track.latitude.to_s + ",lng:" + track.longitude.to_s + "}"
              @track_lat = track.latitude.to_s
              @track_lng = track.longitude.to_s
            end
          end

          #既存の優先順位変更
          @priority_count = 2
          @m_route_recommends = MRouteRecommend.where("route_code=?", params[:route_code_select][:query]).order("priority asc")
          @m_route_recommends.each do |route_recommend|
            m_route_recommend = MRouteRecommend.find(route_recommend.id)
            m_route_recommend.update!(:priority => @priority_count)
            @priority_count = @priority_count + 1
          end
          #追加処理
          MRouteRecommend.create!(:route_code=>params[:route_code_select][:query], :priority=>1, :latlng => @track_latlng, :carrun_id=>params[:carrun_id], :latlng_origin => @track_latlng)
        end
        @m_route = MRoute.where("route_code=?", params[:route_code_select][:query].to_s).first
        change_comment = params[:out_timing].to_s + "　" + @m_route.route_name.to_s
        api_log_hists(104, 1, change_comment)
        @select_params = "&out_date=" + ERB::Util.url_encode(params[:out_timing_str])
        @select_params = @select_params.to_s + "&car_code=" + ERB::Util.url_encode(params[:car_code])
        @select_params = @select_params.to_s + "&route_code=" + ERB::Util.url_encode(params[:route_code_select][:query])
        redirect_to t_carrun_summarys_url.to_s+"/"+params[:carrun_id].to_s+@search_params.to_s+@select_params.to_s, notice: '推奨ルートの設定が完了しました。'
      rescue => e
        @select_params = "&out_date=" + ERB::Util.url_encode(params[:out_timing_str])
        @select_params = @select_params.to_s + "&car_code=" + ERB::Util.url_encode(params[:car_code])
        @select_params = @select_params.to_s + "&route_code=" + ERB::Util.url_encode(params[:route_code_select][:query])
        redirect_to t_carrun_summarys_url.to_s+"/"+params[:carrun_id].to_s+@search_params.to_s+@select_params.to_s, notice: '推奨ルートの設定に失敗しました。'
      end
    elsif params[:route_recommend_flg].to_s=="2"
      # 収集区内ステーション並び順変更の場合
      
      # トランザクション処理
      begin
        ActiveRecord::Base.transaction do
          @t_carrun = TCarrun.find(params[:carrun_id])
          @m_route_points = MRoutePoint.joins("left join (select tcl.cust_kbn, tcl.cust_code, max(tcl.finish_timing) as finish_timing from t_collect_lists tcl inner join t_carruns tc on tc.out_timing=tcl.out_timing and tc.car_code=tcl.car_code where tcl.out_timing>='#{params[:out_timing_str]}' and tcl.out_timing<'#{params[:out_timing_end]}' and tcl.car_code='#{params[:car_code]}' and tc.route_code='#{@t_carrun.route_code}' group by tcl.cust_kbn, tcl.cust_code) tcl on tcl.cust_kbn=m_route_points.cust_kbn and tcl.cust_code=m_route_points.cust_code")
          @m_route_points = @m_route_points.where("m_route_points.route_code=?", @t_carrun.route_code).order(Arel.sql("tcl.finish_timing is null, tcl.finish_timing, m_route_points.tree_no, m_route_points.id"))
          @tree_no = 0
          @m_route_points.each do |m_route_point|
            @tree_no = @tree_no + 1
            MRoutePoint.where("id=?", m_route_point.id).update_all(:tree_no => @tree_no)
          end
          @m_route = MRoute.where("route_code=?", @t_carrun.route_code).first
          change_comment = @m_route.route_code.to_s + ":" + @m_route.route_name.to_s
          api_log_hists(103, 2, change_comment)
        end
        @select_params = "&out_date=" + ERB::Util.url_encode(params[:out_timing_str])
        @select_params = @select_params.to_s + "&car_code=" + ERB::Util.url_encode(params[:car_code])
        @select_params = @select_params.to_s + "&route_code=" + ERB::Util.url_encode(params[:route_code_select][:query])
        redirect_to t_carrun_summarys_url.to_s+"/"+params[:carrun_id].to_s+@search_params.to_s+@select_params.to_s, notice: '収集区内ステーションの並び順変更が完了しました。'
      rescue => e
        @select_params = "&out_date=" + ERB::Util.url_encode(params[:out_timing_str])
        @select_params = @select_params.to_s + "&car_code=" + ERB::Util.url_encode(params[:car_code])
        @select_params = @select_params.to_s + "&route_code=" + ERB::Util.url_encode(params[:route_code_select][:query])
        redirect_to t_carrun_summarys_url.to_s+"/"+params[:carrun_id].to_s+@search_params.to_s+@select_params.to_s, alert: '収集区内ステーションの並び順変更に失敗しました。'
      end
    elsif params[:chg_flg_new]
      # スポット分のステーション登録関連
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
          @custom_check = MCustom.where("cust_kbn='#{G_CUST_KBN_STATION}' and latitude=? and longitude=? and delete_flg=0", params[:latitude_new][0], params[:longitude_new][0]).first
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
              # トランザクション処理
              begin
                ActiveRecord::Base.transaction do
                  custcode = MCustom.where("cust_kbn='#{G_CUST_KBN_STATION}'").maximum(:cust_code).to_i + 1
                  @custcode = "%07d" % custcode
                  #ステーション追加
                  MCustom.create!(:cust_kbn => G_CUST_KBN_STATION, :cust_code => @custcode, :cust_name => params[:cust_name_new][0], :addr_1 => params[:address_new][0], :addr_2 => params[:addr_2_new][0], :latitude => params[:latitude_new][0], :longitude => params[:longitude_new][0], :admin_code => params[:admin_code_new][0], :use_content => params[:use_content_new][0], :shinsei_date => params[:shinsei_date_new][0], :start_date => params[:start_date_new][0], :setai_count => params[:setai_count_new][0], :use_count => params[:use_count_new][0], :memo => params[:memo_new][0], :delete_flg => 0);
                  #日報データ更新
                  TCollectList.where("out_timing=? and car_code=? and spot_no=?", params[:out_timing_new][0].to_s, params[:car_code_new][0].to_s, params[:spot_no_new][0]).update_all(:cust_code=>@custcode,:cust_name=>params[:cust_name_new][0])
                  TCarrunMemo.where("carrun_id=? and finish_timing=? and cust_code='*'",params[:carrun_id_new][0],params[:finish_timing_new][0].to_s).update_all(:cust_code=>@custcode)
                  if params[:route_new]
                    #収集区内に追加
                    @tree_no = MRoutePoint.where("route_code=?", params[:route_code_new][0]).maximum(:tree_no).to_i + 1
                    MRoutePoint.create!(:route_code => params[:route_code_new][0], :tree_no=> @tree_no, :cust_kbn => G_CUST_KBN_STATION, :cust_code => @custcode)
                    @m_route = MRoute.where("route_code=?", params[:route_code_new][0]).first
                    change_comment = @m_route.route_code.to_s + ":" +  @m_route.route_name.to_s + "　" + @custcode.to_s + ":" + params[:cust_name_new][0].to_s
                    api_log_hists(103, 1, change_comment)
                  else
                    change_comment = @custcode.to_s + ":" + params[:cust_name_new][0].to_s
                    api_log_hists(103, 1, change_comment)
                  end
                end
                #redirect_to t_carruns_url.to_s+"/"+params[:carrun_id_new][0].to_s+@search_params.to_s, notice: 'スポット分のステーション登録が完了しました。'
                @ajaxflg = 2
              rescue => e
                @ajaxflg = -1
              end
            else
              #管理者が存在しなかった場合
              @ajaxflg = -5
            end
          else
            # 重複していた場合
            @ajaxflg = -2
          end
        end
      end
    end
  end
  
  private

    def set_itaku
      #委託会社プルダウン用
      @itaku_codes = MCustom.where("cust_kbn=5 and delete_flg=0").order("cust_code asc").map{|i| [i.cust_code.to_s + ':' + i.cust_name.to_s, i.cust_code] }
    end

    def set_use_contents
      @use_contents = MCombo.where("class_1='#{G_USE_CONTENT_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
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
  
    def set_search_params
      @search_param = ""

      if not params[:hold_params].blank?
        @search_params = @search_params.to_s + "hold_params=" + params[:hold_params]
        @search_params = @search_params.to_s + "&outdate_from=" + ERB::Util.url_encode(params[:search_outdate_from])
        @search_params = @search_params.to_s + "&outdate_to=" + ERB::Util.url_encode(params[:search_outdate_to])
        @search_params = @search_params.to_s + "&routecode=" + ERB::Util.url_encode(params[:search_routecode])
        @search_params = @search_params.to_s + "&itakucode=" + ERB::Util.url_encode(params[:search_itakucode])
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
