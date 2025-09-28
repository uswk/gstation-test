class TCarrunListsController < ApplicationController

  before_action :authenticate_user!
  before_action :set_response, :only => [:index]
  before_action :set_itaku, :only => [:index]
  before_action :set_map_key
  before_action :set_zenrin_map_key

  # GET /t_carrunlists
  # GET /t_carrunlists.json
  def index
    create
    #デフォルト緯度経度
    if not @t_carrun_lists.blank?
      @def_latitude = @t_carrun_lists[0].latitude.to_s
      @def_longitude = @t_carrun_lists[0].longitude.to_s
    else
      @def_latitude = A_DEF_LATITUDE
      @def_longitude = A_DEF_LONGITUDE
    end
  end

  # GET /t_carrun_lists/1
  def show
    @header_no_dsp = 1
    
    if params[:search_flg].to_s=="1"
      @date_from = params[:search_from].nil? ? "" : params[:search_from][:query]
      @date_to = params[:search_to].nil? ? "" : params[:search_to][:query]
    else
      @date_from = Date.today.try(:strftime, "%Y/%m/%d")
      @date_to = Date.today.try(:strftime, "%Y/%m/%d")
    end

    strwhere = "t_car_messages.car_id='#{params[:id].to_s}'"
    strwhere = strwhere + " and (t_car_messages.delete_flg is null or t_car_messages.delete_flg=0)"
    # 開始日
    if @date_from != ""
      strwhere = strwhere + " and date(t_car_messages.time) >= '#{@date_from}'"
    end
    # 終了日
    if @date_to != ""
      strwhere = strwhere + " and date(t_car_messages.time) <= '#{@date_to}'"
    end

    @m_car = MCar.where("id=?", params[:id].to_s).first
    
    @t_car_messages = TCarMessage.joins("left join m_combos c on c.class_1='#{G_RESPONSE_TYPE_CLASS_1}' and c.class_2=t_car_messages.response_type and c.class_code=t_car_messages.response_answer").where("#{strwhere}").select("t_car_messages.*,c.class_name as answer_name").page(params[:page]).per("#{G_DEF_PAGE_PER}").order("t_car_messages.id desc")
  end

  def create
    puts request.xhr?
    puts params.inspect

    @now_time = Time.now.try(:strftime, "%Y-%m-%d %H:%M:%S") # 現在の時刻を取得
    
    if params[:msg_flg].to_s == "1"
      # メッセージ送信
      err_flg = 0
      params[:message_chk].length.times do |i|
        if params[:message_chk][i.to_s].to_s!="0"
          @car_id = params[:message_chk][i.to_s].split("_")[0]
          @car_message = TCarMessage.new(:car_id => @car_id, :time => Time.new, :importance_flg => params[:importance_flg], :message => params[:message], :response_type => params[:response_type], :start_date => params[:start_date], :end_date => params[:end_date], :delete_flg => 0)
          if @car_message.save
          else
            err_flg = 1
          end
        end
      end
      if err_flg == 0
        api_log_hists(202, 1, "")
        @ajax_flg = 3
      else
        @ajax_flg = 9
      end
    elsif params[:track].blank?
      carcode = params[:search_car2].nil? ? "" : params[:search_car2][0]
      routecode = params[:search_route2].nil? ? "" : params[:search_route2][0]
      itakucode = params[:search_itaku2].nil? ? "" : params[:search_itaku2][0]

      # 抽出条件
      strwhere_custom = ""
      strwhere_custom2 = ""
      strwhere_item = ""
      strwhere_collect = ""
      strwhere_carrun = ""
      if carcode != ""
        strwhere_custom2 = strwhere_custom2 + " and tcl.car_code='#{carcode}'"
        strwhere_carrun = strwhere_carrun + " and m_cars.car_code = '#{carcode}'"
        strwhere_collect = strwhere_collect + " and t_collect_lists.car_code='#{carcode}'"
      end

      strwhere_custom = strwhere_custom + " and rp.route_code='#{routecode}'"
      strwhere_custom2 = strwhere_custom2 + " and tc.route_code='#{routecode}'"
      strwhere_item = strwhere_item + " and m_route_points.route_code='#{routecode}'"
      strwhere_collect = strwhere_collect + " and tc.route_code='#{routecode}'"

      @now_yobi = Time.now.wday # 現在の曜日を取得
      @now_week = ((Time.now.day+6)/7).truncate # 現在の週を取得
      @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
      @tom_date = (Date.today+1).try(:strftime, "%Y/%m/%d") # 明日の日付を取得
      
      strwhere = "m_customs.delete_flg=0 AND ((rr.run_week=0 AND rr.run_yobi='#{@now_yobi}') OR (rr.run_week='#{@now_week}' AND rr.run_yobi='#{@now_yobi}'))"
      strwhere = strwhere + " AND (m_customs.start_date is null OR m_customs.start_date<='#@now_date')"
      strwhere = strwhere + " AND (m_customs.end_date is null OR m_customs.end_date>='#@now_date')"
      strwhere = strwhere + strwhere_custom.to_s
      @m_customs = MCustom.joins("INNER JOIN m_route_points rp ON rp.cust_kbn=m_customs.cust_kbn AND rp.cust_code=m_customs.cust_code").joins("INNER JOIN m_routes r ON r.route_code=rp.route_code").joins("INNER JOIN m_route_rundates rr ON rr.route_code=r.route_code").joins("LEFT JOIN (SELECT tcl.cust_kbn, tcl.cust_code, MAX(tcl.finish_timing) AS finish_timing, SUM(tcl.mikaishu_count) as mikaishu_count FROM t_collect_lists tcl LEFT JOIN t_carruns tc ON tc.out_timing=tcl.out_timing AND tc.car_code=tcl.car_code WHERE tcl.finish_timing is not null AND tcl.out_timing >= '#{@now_date}' AND tcl.out_timing< '#{@now_date.to_date+1}' #{strwhere_custom2} GROUP BY tcl.cust_kbn, tcl.cust_code) cl ON cl.cust_kbn=rp.cust_kbn AND cl.cust_code=rp.cust_code").where("#{strwhere}").select("m_customs.id, m_customs.cust_kbn, m_customs.cust_code, m_customs.cust_name, m_customs.latitude, m_customs.longitude, cl.finish_timing, cl.mikaishu_count, '' AS mikaishu_name, '' AS info, -4 AS window_id").group("m_customs.id, m_customs.cust_code, m_customs.cust_name, m_customs.latitude, m_customs.longitude, rp.route_code, cl.finish_timing").order("m_customs.cust_kbn, m_customs.cust_code")
      iCount = 0
      @m_customs.each do |custom|
        strwhere = "m_route_points.cust_code='#{custom.cust_code}' AND ((rr.run_week=0 AND rr.run_yobi='#{@now_yobi}') OR (rr.run_week='#{@now_week}' AND rr.run_yobi='#{@now_yobi}'))" + strwhere_item
        @item_names = MRoutePoint.joins("INNER JOIN m_route_rundates rr ON rr.route_code=m_route_points.route_code").joins("INNER JOIN m_combos c ON c.class_1='#{G_ITEM_CLASS_1}' AND c.class_2=0 AND c.class_code=rr.item_kbn").where("#{strwhere}").select("c.class_name, c.value").group("rr.item_kbn, c.value, c.class_name").order("rr.item_kbn")
        @info_text = ""
        @item_names.each do |item_name|
          @info_text = @info_text + "<img src=" + item_name.value + ">&nbsp;"
        end
        @m_customs[iCount].info = ERB::Util.url_encode(@info_text + "<br><br>")
        if custom.finish_timing.nil?
          @m_customs[iCount].info =  ERB::Util.url_encode(@info_text + "<br><h3>&nbsp;<font color=red>本日の回収は終わっていません。</font></h3>")
        else
          @info_text =  @info_text + "<br><h3>&nbsp;回収時間"
          strwhere = "t_collect_lists.cust_kbn='#{custom.cust_kbn}' and t_collect_lists.cust_code='#{custom.cust_code}' and t_collect_lists.finish_timing is not null and t_collect_lists.out_timing >= '#{@now_date}' AND t_collect_lists.out_timing< '#{@now_date.to_date+1}'" + strwhere_collect
          @t_collect_lists = TCollectList.joins("INNER JOIN t_carruns tc ON tc.out_timing=t_collect_lists.out_timing AND tc.car_code=t_collect_lists.car_code").joins("LEFT JOIN m_routes mr ON mr.route_code=tc.route_code").joins("LEFT JOIN m_cars mc ON mc.car_code=tc.car_code").where("#{strwhere}").joins("LEFT JOIN m_combos mi ON mi.class_1='#{G_MIKAISHU_CLASS_1}' and mi.class_2=0 AND mi.class_code=t_collect_lists.mikaishu_code").select("mr.route_name, t_collect_lists.finish_timing, t_collect_lists.mikaishu_count, mc.car_reg_code, mi.class_name as mikaishu_name").order("t_collect_lists.finish_timing")
          @t_collect_lists.each do |t_collect_list|
            @info_text =  @info_text + "<br>&nbsp;<font color=blue>" + t_collect_list.finish_timing.try(:strftime, "%Y/%m/%d %H:%M:%S") + "&nbsp;（" + t_collect_list.route_name + "　" + t_collect_list.car_reg_code + "）"
            if not t_collect_list.mikaishu_count.blank?
              @info_text =  @info_text + "<br>&nbsp;&nbsp;&nbsp;<font color=red>" + t_collect_list.mikaishu_name.to_s + "：" + t_collect_list.mikaishu_count.to_s + "</font>"
            end
          end
          @info_text =  @info_text + "</font></h3>"
          @m_customs[iCount].info =  ERB::Util.url_encode(@info_text)
        end
        iCount = iCount + 1
      end
      
      @m_route_points = @m_customs
      @m_combo = MCombo.where("class_1=? AND class_2=0 AND class_code=?", G_YOBI_CLASS_1, @now_yobi).first
      
      # 車両
      if current_user.itaku_code.blank?
        if itakucode != ""
          carwhere = "delete_flg = 0 and itaku_code='#{itakucode}'"
        else
          carwhere = "delete_flg = 0"
        end
      else
        carwhere = "delete_flg = 0 and itaku_code='#{current_user.itaku_code}'"
      end
      @m_cars = MCar.where("#{carwhere}").order("car_code asc").map{|i| [i.car_reg_code, i.car_code] }
      
      # 収集区
      if current_user.itaku_code.blank?
        if itakucode != ""
          routewhere = "m_routes.delete_flg = 0 and mrr.itaku_code='#{itakucode}'"
        else
          routewhere = "m_routes.delete_flg = 0"
        end
      else
        routewhere = "m_routes.delete_flg = 0 and mrr.itaku_code='#{current_user.itaku_code}'"
      end
      @route_codes = MRoute.joins("left join m_route_rundates mrr on mrr.route_code=m_routes.route_code")
      @route_codes = @route_codes.where("#{routewhere}").group("m_routes.route_code, m_routes.route_name").order("m_routes.route_code asc").map{|i| [i.route_code.to_s + ':' + i.route_name.to_s, i.route_code] }

      # 車両コード
      strwhere = " m_cars.delete_flg=0" + strwhere_carrun
      if not current_user.itaku_code.blank?
        strwhere = strwhere + " and m_cars.itaku_code='#{current_user.itaku_code}'"
      else
        if itakucode != ""
          strwhere = strwhere + " and m_cars.itaku_code='#{itakucode}'"
        end
      end
      @t_tracks = MCar.joins("left join (select car_code, max(id) as max_id from t_tracks where time>='#@now_date' and time<'#@tom_date' group by car_code) t on t.car_code=m_cars.car_code")
      @t_tracks = @t_tracks.joins("left join (select car_id as msg_car_id, max(response_answer) as msg_max_answer from t_car_messages where ((start_date>='#@now_date' and end_date<'#@tom_date') or (start_date<'#@now_date' and end_date>='#@now_date') or (start_date<'#@tom_date' and end_date>='#@tom_date')) and delete_flg=0 group by car_id) tcm on tcm.msg_car_id=m_cars.id")
      @t_tracks = @t_tracks.where("#{strwhere}")
      @t_tracks = @t_tracks.joins("left join t_tracks tt on tt.id=t.max_id")
      @t_tracks = @t_tracks.joins("left join t_carruns tc on tc.out_timing=tt.out_timing and tc.car_code=tt.car_code")
      @t_tracks = @t_tracks.joins("left join m_drivers md on md.driver_code=tc.driver_code")
      @t_tracks = @t_tracks.joins("left join m_drivers smd1 on smd1.driver_code=tc.sub_driver_code1")
      @t_tracks = @t_tracks.joins("left join m_drivers smd2 on smd2.driver_code=tc.sub_driver_code2")
      @t_tracks = @t_tracks.select("tt.latitude, tt.longitude, tt.time, m_cars.id as car_id, m_cars.car_code, m_cars.car_reg_code, tcm.msg_car_id, tcm.msg_max_answer, tc.driver_code, tc.sub_driver_code1, tc.sub_driver_code2, md.driver_name, smd1.driver_name as sub_driver_name1, smd2.driver_name as sub_driver_name2")
      @t_tracks = @t_tracks.order("m_cars.car_code asc, m_cars.id asc")
      
      @ajax_flg=1
    else
      #軌跡表示
      @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
      @tom_date = (Date.today+1).try(:strftime, "%Y/%m/%d") # 明日の日付を取得
      @track_latlng = ""
      @tracks = TTrack.where("t_tracks.time>=? and t_tracks.time<? and t_tracks.car_code=? and t_tracks.latitude is not null and t_tracks.longitude is not null", @now_date, @tom_date, params[:track][:car_code].to_s).select("car_code, group_concat(DISTINCT CONCAT('{lat:',latitude,',lng:',longitude,',time:',DATE_FORMAT(time,'%Y%m%d%H%i%S'),'}') ORDER BY time, id SEPARATOR ',') as latlng").group("car_code")
      @tracks.each do |track|
        @track_latlng = track.latlng.to_s
      end
      
      #@tracks = TTrack.where("t_tracks.time>=? and t_tracks.time<? and t_tracks.car_code=? and t_tracks.latitude is not null and t_tracks.longitude is not null", @now_date, @tom_date, params[:track][:car_code].to_s).order("t_tracks.out_timing, t_tracks.time, t_tracks.id")
      @ajax_flg=2
    end
  end
  
  # DELETE /t_carrun_lists/1
  def destroy
    @t_car_message = TCarMessage.find(params[:id])
    @t_car_message.update(:delete_flg => 1)
    api_log_hists(202, 3, "")
    respond_to do |format|
      format.html { redirect_to t_carrun_lists_url.to_s + "/" + @t_car_message.car_id.to_s }
    end
  end
  
  private
  
    def set_response
      @responses = MCombo.where("class_1=? and delete_flg=0", G_RESPONSE_TYPE_CLASS_1).group("class_2").order("class_2").select("class_2, max(value) as value_name").map{|i| [i.value_name, i.class_2] }
    end

    def set_itaku
      #委託会社プルダウン用
      @itaku_codes = MCustom.where("cust_kbn=5 and delete_flg=0").order("cust_code asc").map{|i| [i.cust_code.to_s + ':' + i.cust_name.to_s, i.cust_code] }
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
