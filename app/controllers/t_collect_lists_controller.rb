class TCollectListsController < ApplicationController
 
  before_action :authenticate_user!
  before_action :set_map_key
  before_action :set_zenrin_map_key

  def index
    @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
    @mikaishu_codes = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_MIKAISHU_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    # 荷下先存在チェック
    @unload_flg = MCustom.where("cust_kbn=? and delete_flg=0", G_CUST_KBN_UNLOAD).first
    @iCount_unload = 0
            
    if params[:id].nil?
      @t_carrun = TCarrun.new
      @routecode = params[:add][:route_code]
      @outtiming = params[:add][:out_timing]
      @now_yobi = @outtiming.to_date.wday # 曜日を取得
      @now_week = ((@outtiming.to_date.day+6)/7).truncate # 週を取得
      @carcode = params[:add][:car_code]
      @m_route = MRoute.where("route_code = ?", @routecode).first
      @routename = @m_route.route_name
      @input_flg = 1
      @use_item_flg = @m_route.use_item_flg.blank? ? 0 : @m_route.use_item_flg
      
      #廃棄物数量入力時
      @iCount = 0
      @strselect = ""
      if @use_item_flg.to_s=="1"
        rundatewhere = " and ((m_route_rundates.run_week=0 AND m_route_rundates.run_yobi='#{@now_yobi}') OR (m_route_rundates.run_week='#{@now_week}' AND m_route_rundates.run_yobi='#{@now_yobi}'))"
        if not current_user.itaku_code.blank?
          rundatewhere = rundatewhere + " and itaku_code='#{current_user.itaku_code}'"
        end
        @t_collect_details = MRouteRundate.joins("left join m_combos item on item.class_1='#{G_ITEM_CLASS_1}' and item.class_code=m_route_rundates.item_kbn")
        @t_collect_details = @t_collect_details.joins("left join m_combos unit on unit.class_1='#{G_UNIT_CLASS_1}' and unit.class_code=m_route_rundates.unit_kbn")
        @t_collect_details = @t_collect_details.select("m_route_rundates.item_kbn, m_route_rundates.unit_kbn, item.class_name as item_name, unit.class_name as unit_name")
        @t_collect_details = @t_collect_details.where("m_route_rundates.route_code=?"+rundatewhere.to_s, @routecode).group("m_route_rundates.route_code, m_route_rundates.item_kbn").order("m_route_rundates.route_code, m_route_rundates.item_kbn")
        @t_collect_details.each do |t_collect_detail|
          @iCount = @iCount + 1
          @strselect = @strselect + ", '" + t_collect_detail.item_kbn.to_s + "' as item_kbn_" + @iCount.to_s
          @strselect = @strselect + ", '" + t_collect_detail.unit_kbn.to_s + "' as unit_kbn_" + @iCount.to_s
          @strselect = @strselect + ", '" + t_collect_detail.item_name.to_s + "' as item_name_" + @iCount.to_s
          @strselect = @strselect + ", '" + t_collect_detail.unit_name.to_s + "' as unit_name_" + @iCount.to_s
          @strselect = @strselect + ", null as item_count_" + @iCount.to_s
          @strselect = @strselect + ", " + @iCount.to_s + " as iCount"
        end
      end
      @m_customs = MCustom.joins("INNER JOIN m_route_points rp ON rp.cust_kbn=m_customs.cust_kbn AND rp.cust_code=m_customs.cust_code AND rp.route_code='#{@routecode}'")
      @m_customs = @m_customs.where("m_customs.delete_flg=0 AND m_customs.cust_kbn='#{G_CUST_KBN_STATION}' AND m_customs.latitude is not null AND m_customs.longitude is not null")
      @m_customs = @m_customs.select("m_customs.cust_kbn, m_customs.cust_code, m_customs.cust_name, m_customs.latitude, m_customs.longitude, null as out_timing, null as car_code, rp.tree_no, null as finish_timing, null as mikaishu_count, null as mikaishu_code, null as mikaishu_name, '#{@mikaishu_codes}' AS mikaishu_codes, case when (m_customs.start_date is null OR m_customs.start_date<='#{@now_date}') AND (m_customs.end_date is null OR m_customs.end_date>='#{@now_date}') then '' else 'lightgrey' end as bgcolor, null as memo_flg" + @strselect.to_s).order("rp.tree_no, m_customs.cust_code")
      @chg_flg = 1
    else
      @t_carrun = TCarrun.joins("LEFT JOIN m_routes r ON r.route_code=t_carruns.route_code").where("t_carruns.id=?", params[:id]).select("t_carruns.*, r.route_name").first
      @routecode = @t_carrun.route_code
      @routename = @t_carrun.route_name
      @input_flg = @t_carrun.input_flg
      @use_item_flg = @t_carrun.use_item_flg.blank? ? 0 : @t_carrun.use_item_flg
      @now_yobi = @t_carrun.out_timing.to_date.wday # 曜日を取得
      @now_week = ((@t_carrun.out_timing.to_date.day+6)/7).truncate # 週を取得
      
      @m_customs = TCollectList.joins("inner join t_carruns tc on tc.out_timing=t_collect_lists.out_timing and tc.car_code=t_collect_lists.car_code")
      @m_customs = @m_customs.joins("LEFT JOIN m_customs ON t_collect_lists.cust_kbn=m_customs.cust_kbn AND t_collect_lists.cust_code=m_customs.cust_code")
      @m_customs = @m_customs.joins("left join (select carrun_id, cust_kbn, cust_code from t_carrun_memos where cust_code<>'*' group by carrun_id, cust_kbn, cust_code) tcm1 on tcm1.carrun_id=tc.id and tcm1.cust_kbn=t_collect_lists.cust_kbn and tcm1.cust_code=t_collect_lists.cust_code")
      @m_customs = @m_customs.joins("left join (select carrun_id, finish_timing from t_carrun_memos where cust_code='*' group by carrun_id, finish_timing) tcm2 on tcm2.carrun_id=tc.id and tcm2.finish_timing=t_collect_lists.finish_timing")
      @m_customs = @m_customs.joins("left join m_combos mikai on mikai.class_1='#{G_MIKAISHU_CLASS_1}' and mikai.class_code=t_collect_lists.mikaishu_code")
      #廃棄物数量入力時
      @iCount = 0
      @strselect = ""
      if @use_item_flg.to_s=="1"
        @t_collect_details = TCollectDetail.joins("inner join t_collect_lists tcl on tcl.out_timing=t_collect_details.out_timing and tcl.car_code=t_collect_details.car_code and tcl.spot_no=t_collect_details.spot_no")
        @t_collect_details = @t_collect_details.joins("left join m_combos item on item.class_1='#{G_ITEM_CLASS_1}' and item.class_code=t_collect_details.item_kbn")
        @t_collect_details = @t_collect_details.joins("left join m_combos unit on unit.class_1='#{G_UNIT_CLASS_1}' and unit.class_code=t_collect_details.unit_kbn")
        @t_collect_details = @t_collect_details.select("t_collect_details.item_kbn, t_collect_details.unit_kbn, item.class_name as item_name, unit.class_name as unit_name")
        @t_collect_details = @t_collect_details.where("t_collect_details.out_timing=? and t_collect_details.car_code=? and tcl.cust_kbn=?", @t_carrun.out_timing.try(:strftime, "%Y-%m-%d %H:%M:%S"), @t_carrun.car_code, G_CUST_KBN_STATION).group("t_collect_details.item_kbn").order("t_collect_details.item_kbn")
        @t_collect_details.each do |t_collect_detail|
          @iCount = @iCount + 1
          @strselect = @strselect + ", '" + t_collect_detail.item_kbn.to_s + "' as item_kbn_" + @iCount.to_s
          @strselect = @strselect + ", '" + t_collect_detail.unit_kbn.to_s + "' as unit_kbn_" + @iCount.to_s
          @strselect = @strselect + ", '" + t_collect_detail.item_name.to_s + "' as item_name_" + @iCount.to_s
          @strselect = @strselect + ", '" + t_collect_detail.unit_name.to_s + "' as unit_name_" + @iCount.to_s
          @strselect = @strselect + ", tcd" + @iCount.to_s + ".item_count as item_count_" + @iCount.to_s
          @strselect = @strselect + ", " + @iCount.to_s + " as iCount"
          @m_customs = @m_customs.joins("left join t_collect_details tcd" + @iCount.to_s + " on tcd" + @iCount.to_s + ".out_timing=t_collect_lists.out_timing and tcd" + @iCount.to_s + ".car_code=t_collect_lists.car_code and tcd" + @iCount.to_s + ".spot_no=t_collect_lists.spot_no and tcd" + @iCount.to_s + ".item_kbn=" + t_collect_detail.item_kbn.to_s)
        end
        if @iCount==0  #廃棄物がなかったらマスタから取得
          @t_collect_details = MRouteRundate.joins("left join m_combos item on item.class_1='#{G_ITEM_CLASS_1}' and item.class_code=m_route_rundates.item_kbn")
          @t_collect_details = @t_collect_details.joins("left join m_combos unit on unit.class_1='#{G_UNIT_CLASS_1}' and unit.class_code=m_route_rundates.unit_kbn")
          @t_collect_details = @t_collect_details.select("m_route_rundates.item_kbn, m_route_rundates.unit_kbn, item.class_name as item_name, unit.class_name as unit_name")
          @t_collect_details = @t_collect_details.where("m_route_rundates.route_code=?"+rundatewhere.to_s, @routecode).group("m_route_rundates.route_code, m_route_rundates.item_kbn").order("m_route_rundates.route_code, m_route_rundates.item_kbn")
          @t_collect_details.each do |t_collect_detail|
            @iCount = @iCount + 1
            @strselect = @strselect + ", '" + t_collect_detail.item_kbn.to_s + "' as item_kbn_" + @iCount.to_s
            @strselect = @strselect + ", '" + t_collect_detail.unit_kbn.to_s + "' as unit_kbn_" + @iCount.to_s
            @strselect = @strselect + ", '" + t_collect_detail.item_name.to_s + "' as item_name_" + @iCount.to_s
            @strselect = @strselect + ", '" + t_collect_detail.unit_name.to_s + "' as unit_name_" + @iCount.to_s
            @strselect = @strselect + ", null as item_count_" + @iCount.to_s
            @strselect = @strselect + ", " + @iCount.to_s + " as iCount"
          end
        end
      end
      @m_customs = @m_customs.where("t_collect_lists.out_timing=? and t_collect_lists.car_code=? and t_collect_lists.cust_kbn=? and (t_collect_lists.latitude is not null AND t_collect_lists.longitude is not null)", @t_carrun.out_timing.try(:strftime, "%Y-%m-%d %H:%M:%S"), @t_carrun.car_code, G_CUST_KBN_STATION)
      @m_customs = @m_customs.select("t_collect_lists.cust_kbn, t_collect_lists.cust_code, t_collect_lists.cust_name, t_collect_lists.latitude, t_collect_lists.longitude, t_collect_lists.out_timing, t_collect_lists.car_code, t_collect_lists.spot_no as tree_no, t_collect_lists.finish_timing, t_collect_lists.mikaishu_count, t_collect_lists.mikaishu_code, mikai.class_name as mikaishu_name, '#{@mikaishu_codes}' AS mikaishu_codes, case when m_customs.id is null then 'lightgreen' else case when (m_customs.start_date is null OR m_customs.start_date<='#{@now_date}') AND (m_customs.end_date is null OR m_customs.end_date>='#{@now_date}') then '' else 'lightgrey' end end as bgcolor,case when t_collect_lists.cust_code='*' then tcm2.carrun_id else tcm1.carrun_id end as memo_flg" + @strselect.to_s).order("t_collect_lists.spot_no, m_customs.cust_code")
      
      # 荷下先
      if not @unload_flg.blank?
        @unloads = TCollectList.joins("inner join t_carruns tc on tc.out_timing=t_collect_lists.out_timing and tc.car_code=t_collect_lists.car_code")
        @unloads = @unloads.joins("left join m_customs mc ON t_collect_lists.cust_kbn=mc.cust_kbn AND t_collect_lists.cust_code=mc.cust_code")
        @strselect_unload = ""
        
        @unload_details = TCollectDetail.joins("inner join t_collect_lists tcl on tcl.out_timing=t_collect_details.out_timing and tcl.car_code=t_collect_details.car_code and tcl.spot_no=t_collect_details.spot_no")
        @unload_details = @unload_details.joins("left join m_combos item on item.class_1='#{G_ITEM_CLASS_1}' and item.class_code=t_collect_details.item_kbn")
        @unload_details = @unload_details.joins("left join m_combos unit on unit.class_1='#{G_UNIT_CLASS_1}' and unit.class_code=t_collect_details.unit_kbn")
        @unload_details = @unload_details.select("t_collect_details.item_kbn, t_collect_details.item_count, t_collect_details.item_weight, t_collect_details.unit_kbn, item.class_name as item_name, unit.class_name as unit_name")
        @unload_details = @unload_details.where("t_collect_details.out_timing=? and t_collect_details.car_code=? and tcl.cust_kbn=?", @t_carrun.out_timing.try(:strftime, "%Y-%m-%d %H:%M:%S"), @t_carrun.car_code, G_CUST_KBN_UNLOAD).group("t_collect_details.item_kbn").order("t_collect_details.item_kbn")
        @unload_details.each do |unload_detail|
          @iCount_unload = @iCount_unload + 1
          @strselect_unload = @strselect_unload + ", '" + unload_detail.item_kbn.to_s + "' as item_kbn_" + @iCount_unload.to_s
          @strselect_unload = @strselect_unload + ", '" + unload_detail.item_name.to_s + "' as item_name_" + @iCount_unload.to_s
          @strselect_unload = @strselect_unload + ", tcd" + @iCount_unload.to_s + ".item_count as item_count_" + @iCount_unload.to_s
          @strselect_unload = @strselect_unload + ", tcd" + @iCount_unload.to_s + ".unit_kbn as unit_kbn_" + @iCount_unload.to_s
          @strselect_unload = @strselect_unload + ", unit" + @iCount_unload.to_s + ".class_name as unit_name_" + @iCount_unload.to_s
          @strselect_unload = @strselect_unload + ", " + @iCount_unload.to_s + " as iCount"
          @unloads = @unloads.joins("left join t_collect_details tcd" + @iCount_unload.to_s + " on tcd" + @iCount_unload.to_s + ".out_timing=t_collect_lists.out_timing and tcd" + @iCount_unload.to_s + ".car_code=t_collect_lists.car_code and tcd" + @iCount_unload.to_s + ".spot_no=t_collect_lists.spot_no and tcd" + @iCount_unload.to_s + ".item_kbn='" + unload_detail.item_kbn.to_s + "'")
          @unloads = @unloads.joins("left join m_combos unit" + @iCount_unload.to_s + " on unit" + @iCount_unload.to_s + ".class_1='#{G_UNIT_CLASS_1}' and unit" + @iCount_unload.to_s + ".class_code=tcd" + @iCount_unload.to_s + ".unit_kbn")
        end
        @unloads = @unloads.where("t_collect_lists.out_timing=? and t_collect_lists.car_code=? and t_collect_lists.cust_kbn=?", @t_carrun.out_timing.try(:strftime, "%Y-%m-%d %H:%M:%S"), @t_carrun.car_code, G_CUST_KBN_UNLOAD)
        @unloads = @unloads.select("t_collect_lists.cust_kbn, t_collect_lists.cust_code, t_collect_lists.cust_name, t_collect_lists.latitude, t_collect_lists.longitude, t_collect_lists.out_timing, t_collect_lists.car_code, t_collect_lists.spot_no as tree_no, t_collect_lists.finish_timing" + @strselect_unload.to_s)
        @unloads = @unloads.group("t_collect_lists.id, t_collect_lists.spot_no, mc.cust_code").order("t_collect_lists.spot_no, mc.cust_code")
      end
      @chg_flg = 2
    end
    @m_route_area = MRouteArea.where("route_code=?", @routecode).first
    if @m_route_area.nil?
      @latlng = ""
    else
      @latlng = ERB::Util.url_encode(@m_route_area.latlng)
    end
    @m_custom = @m_customs.first
    if @m_custom.nil?
      @def_lat = A_DEF_LATITUDE
      @def_lng = A_DEF_LONGITUDE
    else
      @def_lat = @m_custom.latitude
      @def_lng = @m_custom.longitude
    end
    @m_route_points = @m_customs
    
    # 車両
    if current_user.itaku_code.blank?
      strwhere = "delete_flg = 0"
    else
      strwhere = "delete_flg = 0 and itaku_code='#{current_user.itaku_code}'"
    end
    @car_codes = MCar.where("#{strwhere}").order("car_code asc").map{|i| [i.car_reg_code, i.car_code] }
    # 運転手
    @driver_codes = MDriver.where("#{strwhere}").order("driver_code asc").map{|i| [i.driver_name, i.driver_code] }
    @item_kbns = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_ITEM_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @unit_kbns = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_UNIT_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
  end
  
  def show
    # Excel書き出し
    require 'axlsx'
    pkg = Axlsx::Package.new
    pkg.workbook do |wb|
      setup = {:orientation => :landscape, :paper_size => 9, :fit_to_page=>true}
      header_footer = {:different_first => false, :odd_header=>'運転日報',:odd_footer=>'page : &P/&N'}
      wb.add_worksheet(:name => '運転日報', :page_setup => setup, :header_footer=>header_footer) do |ws|   # シート名の指定は省略可
        if params[:out_date].blank?
          t_carrun = TCarrun.joins("left join m_routes mr on mr.route_code=t_carruns.route_code")
          t_carrun = t_carrun.joins("left join m_cars mc on mc.car_code=t_carruns.car_code")
          t_carrun = t_carrun.joins("left join m_drivers md on md.driver_code=t_carruns.driver_code")
          t_carrun = t_carrun.joins("left join m_drivers smd1 on smd1.driver_code=t_carruns.sub_driver_code1")
          t_carrun = t_carrun.joins("left join m_drivers smd2 on smd2.driver_code=t_carruns.sub_driver_code2")
          t_carrun = t_carrun.joins("left join t_fee_gasses tfg on tfg.out_timing=t_carruns.out_timing and tfg.car_code=t_carruns.car_code")
          t_carrun = t_carrun.select("t_carruns.*, mr.route_name, mc.car_reg_code, md.driver_name, smd1.driver_name as sub_driver_name1, smd2.driver_name as sub_driver_name2, sum(tfg.quantity) as fee_quantity").where("t_carruns.id=?",params[:id]).group("t_carruns.out_timing, t_carruns.car_code").first
        else
          t_carrun = TCarrun.joins("left join m_cars ON m_cars.car_code=t_carruns.car_code")
          t_carrun = t_carrun.joins("left join m_drivers md on md.driver_code=t_carruns.driver_code")
          t_carrun = t_carrun.joins("left join m_drivers smd1 on smd1.driver_code=t_carruns.sub_driver_code1")
          t_carrun = t_carrun.joins("left join m_drivers smd2 on smd2.driver_code=t_carruns.sub_driver_code2")
          t_carrun = t_carrun.joins("left join m_routes ON m_routes.route_code=t_carruns.route_code")
          t_carrun = t_carrun.joins("left join m_customs itaku ON itaku.cust_kbn='#{G_CUST_KBN_GYOSHA}' and itaku.cust_code=m_cars.itaku_code")
          t_carrun = t_carrun.joins("left join t_fee_gasses tfg on tfg.out_timing=t_carruns.out_timing and tfg.car_code=t_carruns.car_code")
          t_carrun = t_carrun.page(params[:page]).per("#{G_DEF_PAGE_PER}")
          t_carrun = t_carrun.select("t_carruns.id, min(t_carruns.out_timing) as out_timing, t_carruns.car_code, t_carruns.route_code, case when max(ifnull(t_carruns.in_timing,'2200-12-31'))='2200-12-31' then null else max(t_carruns.in_timing) end as in_timing, max(t_carruns.use_item_flg) as use_item_flg, sum(t_carruns.run_distance) as run_distance, min(t_carruns.mater_out) as mater_out, max(t_carruns.mater_in) as mater_in, m_cars.car_reg_code, m_routes.route_name, itaku.cust_name as itaku_name, md.driver_name, smd1.driver_name as sub_driver_name1, smd2.driver_name as sub_driver_name2, sum(tfg.quantity) as fee_quantity")
          t_carrun = t_carrun.where("t_carruns.out_timing>=? and t_carruns.out_timing<? and t_carruns.car_code=? and t_carruns.route_code=?",params[:out_date].to_date, params[:out_date].to_date.tomorrow.strftime("%Y/%m/%d"), params[:car_code], params[:route_code])
          t_carrun = t_carrun.group("DATE_FORMAT(t_carruns.out_timing, '%Y%m%d'), t_carruns.car_code, t_carruns.route_code").first
        end
        header_style = ws.styles.add_style :sz => 9, :border => {:style => :thin, :color => "FF333333"}
        dheader_style = ws.styles.add_style :sz => 9, :bg_color => "C0C0C0", :border => {:style => :thin, :color => "FF333333"}
        detail_style = ws.styles.add_style :sz => 9, :border => {:style => :thin, :color => "FF333333"}
        # ヘッダ行
        ws.add_row()
        ws.add_row(['収集区',nil, t_carrun.route_name,nil,nil], :style=>[dheader_style,dheader_style,header_style,dheader_style,header_style], :bg_color=>[:bg_color=>"C0C0C0"])
        ws.add_row(['車両',nil, t_carrun.car_reg_code,'走行距離(GPS)',t_carrun.run_distance], :style=>[dheader_style,dheader_style,header_style,dheader_style,header_style])
        ws.add_row(['運転手',nil, t_carrun.driver_name,'走行距離(手入力)',t_carrun.mater_in.to_i - t_carrun.mater_out.to_i], :style=>[dheader_style,dheader_style,header_style,dheader_style,header_style])
        ws.add_row(['副乗務員1',nil, t_carrun.sub_driver_name1,nil,nil], :style=>[dheader_style,dheader_style,header_style,dheader_style,header_style])
        ws.add_row(['副乗務員2',nil, t_carrun.sub_driver_name2,'給油量(ℓ)',t_carrun.fee_quantity], :style=>[dheader_style,dheader_style,header_style,dheader_style,header_style])
        ws.add_row(['出庫時間',nil, t_carrun.out_timing.try(:strftime, "%Y/%m/%d %H:%M:%S"),'出庫メーター値(km)',t_carrun.mater_out], :style=>[dheader_style,dheader_style,header_style,dheader_style,header_style])
        ws.add_row(['帰庫時間',nil, t_carrun.in_timing.try(:strftime, "%Y/%m/%d %H:%M:%S"),'帰庫メーター値(km)',t_carrun.mater_in], :style=>[dheader_style,dheader_style,header_style,dheader_style,header_style])
        ws.add_row()
        ws.merge_cells "A2:B2"
        ws.merge_cells "A3:B3"
        ws.merge_cells "A4:B4"
        ws.merge_cells "A5:B5"
        ws.merge_cells "A6:B6"
        ws.merge_cells "A7:B7"
        ws.merge_cells "A8:B8"
        ws.merge_cells "C2:E2"
        #ws.merge_cells "C3:D3"
        #ws.merge_cells "C4:E4"
        ws.merge_cells "C5:E5"
        #ws.merge_cells "C6:E6"
        #ws.merge_cells "C7:D7"
        #ws.merge_cells "C8:D8"
        
        # 明細ヘッダ
        @arrHeader = ['SEQ', 'ｽﾃｰｼｮﾝID','ステーション名','住所','備考','管理者名','電話番号','Eメール','収集時間']
        @arrWidth = [5, 7, 17, 24, 18, 14, 11, 15, 7]
        
        #廃棄物数量入力時
        @iCount = 0
        @strselect = ""
        @t_collect_list_join = nil

        if params[:out_date].blank? #通常用
          @t_collect_details = TCollectDetail.joins("inner join t_collect_lists tcl on tcl.out_timing=t_collect_details.out_timing and tcl.car_code=t_collect_details.car_code and tcl.spot_no=t_collect_details.spot_no")
          @t_collect_details = @t_collect_details.joins("left join m_combos item on item.class_1='#{G_ITEM_CLASS_1}' and item.class_code=t_collect_details.item_kbn")
          @t_collect_details = @t_collect_details.joins("left join m_combos unit on unit.class_1='#{G_UNIT_CLASS_1}' and unit.class_code=t_collect_details.unit_kbn")
          @t_collect_details = @t_collect_details.select("t_collect_details.item_kbn, t_collect_details.unit_kbn, item.class_name as item_name, unit.class_name as unit_name")
          @t_collect_details = @t_collect_details.where("t_collect_details.out_timing=? and t_collect_details.car_code=?", t_carrun.out_timing.try(:strftime, "%Y-%m-%d %H:%M:%S"), t_carrun.car_code).group("t_collect_details.item_kbn").order("t_collect_details.item_kbn")
          @t_collect_details.each do |t_collect_detail|
            @iCount = @iCount + 1
            @strselect = @strselect + ", '" + t_collect_detail.item_kbn.to_s + "' as item_kbn_" + @iCount.to_s
            @strselect = @strselect + ", '" + t_collect_detail.unit_kbn.to_s + "' as unit_kbn_" + @iCount.to_s
            @strselect = @strselect + ", '" + t_collect_detail.item_name.to_s + "' as item_name_" + @iCount.to_s
            @strselect = @strselect + ", '" + t_collect_detail.unit_name.to_s + "' as unit_name_" + @iCount.to_s
            @strselect = @strselect + ", case when t_collect_lists.cust_kbn='#{G_CUST_KBN_UNLOAD}' then tcd" + @iCount.to_s + ".item_count*-1 else tcd" + @iCount.to_s + ".item_count end as item_count_" + @iCount.to_s
            @strselect = @strselect + ", " + @iCount.to_s + " as iCount"
            @arrHeader[@iCount+8] = t_collect_detail.item_name.to_s
            @arrWidth[@iCount+8] = 10
          end
        else  #サマリー用
          @t_collect_details = TCollectDetail.joins("inner join t_collect_lists tcl on tcl.out_timing=t_collect_details.out_timing and tcl.car_code=t_collect_details.car_code and tcl.spot_no=t_collect_details.spot_no")
          @t_collect_details = @t_collect_details.joins("inner join t_carruns tc on tc.out_timing=tcl.out_timing and tc.car_code=tcl.car_code")
          @t_collect_details = @t_collect_details.joins("left join m_combos item on item.class_1='#{G_ITEM_CLASS_1}' and item.class_code=t_collect_details.item_kbn")
          @t_collect_details = @t_collect_details.joins("left join m_combos unit on unit.class_1='#{G_UNIT_CLASS_1}' and unit.class_code=t_collect_details.unit_kbn")
          @t_collect_details = @t_collect_details.select("t_collect_details.item_kbn, t_collect_details.unit_kbn, item.class_name as item_name, unit.class_name as unit_name")
          @t_collect_details = @t_collect_details.where("t_collect_details.out_timing>=? and t_collect_details.out_timing<? and t_collect_details.car_code=? and tc.route_code=? and tcl.finish_timing is not null", params[:out_date].to_date, params[:out_date].to_date.tomorrow.strftime("%Y/%m/%d"), params[:car_code], params[:route_code]).group("t_collect_details.item_kbn").order("t_collect_details.item_kbn")
          @t_collect_details.each do |t_collect_detail|
            @iCount = @iCount + 1
            @strselect = @strselect + ", '" + t_collect_detail.item_kbn.to_s + "' as item_kbn_" + @iCount.to_s
            @strselect = @strselect + ", '" + t_collect_detail.unit_kbn.to_s + "' as unit_kbn_" + @iCount.to_s
            @strselect = @strselect + ", '" + t_collect_detail.item_name.to_s + "' as item_name_" + @iCount.to_s
            @strselect = @strselect + ", '" + t_collect_detail.unit_name.to_s + "' as unit_name_" + @iCount.to_s
            @strselect = @strselect + ", sum(case when t_collect_lists.cust_kbn='#{G_CUST_KBN_UNLOAD}' then tcd" + @iCount.to_s + ".item_count*-1 else tcd" + @iCount.to_s + ".item_count end) as item_count_" + @iCount.to_s
            @strselect = @strselect + ", " + @iCount.to_s + " as iCount"
            @arrHeader[@iCount+8] = t_collect_detail.item_name.to_s
            @arrWidth[@iCount+8] = 10
          end
        end
        
        # 明細ヘッダ
        @arrHeader[@iCount+9] = "未回収数"
        @arrHeader[@iCount+10] = "未回収理由"
        @arrWidth[@iCount+9] = 7
        @arrWidth[@iCount+10] = 12
        
        ws.add_row(@arrHeader, :style=>dheader_style)
        # 明細一覧
        if params[:out_date].blank?  #通常用
          @t_collect_lists = TCollectList.joins("left join m_customs mc on mc.cust_kbn=t_collect_lists.cust_kbn and mc.cust_code=t_collect_lists.cust_code")
          @t_collect_lists = @t_collect_lists.joins("left join m_customs mc2 on mc2.cust_kbn='#{G_CUST_KBN_ADMIN}' and mc2.cust_code=mc.admin_code")
          @t_collect_lists = @t_collect_lists.joins("LEFT JOIN m_combos c ON c.class_1 = '#{G_MIKAISHU_CLASS_1}' AND c.class_2=0 AND c.class_code = t_collect_lists.mikaishu_code")
          @iCount = 0
          if not @t_collect_details.nil?
            @t_collect_details.each do |t_collect_detail|
              @iCount = @iCount + 1
              @t_collect_lists = @t_collect_lists.joins("left join t_collect_details tcd" + @iCount.to_s + " on tcd" + @iCount.to_s + ".out_timing=t_collect_lists.out_timing and tcd" + @iCount.to_s + ".car_code=t_collect_lists.car_code and tcd" + @iCount.to_s + ".spot_no=t_collect_lists.spot_no and tcd" + @iCount.to_s + ".item_kbn=" + t_collect_detail.item_kbn.to_s)
            end
          end
          @t_collect_lists = @t_collect_lists.select("t_collect_lists.*, mc.addr_1, mc.addr_2, mc.memo, mc2.cust_name as admin_name, mc2.tel_no, mc2.email, c.class_name as mikaishu_name"+@strselect.to_s)
          @t_collect_lists = @t_collect_lists.where("t_collect_lists.out_timing=? and t_collect_lists.car_code=?", t_carrun.out_timing, t_carrun.car_code).order("t_collect_lists.spot_no")
        else  #サマリー用
          @t_collect_lists = TCollectList.joins("INNER JOIN t_carruns tc on tc.out_timing=t_collect_lists.out_timing and tc.car_code=t_collect_lists.car_code")
          @t_collect_lists = @t_collect_lists.joins("left join m_customs mc on mc.cust_kbn=t_collect_lists.cust_kbn and mc.cust_code=t_collect_lists.cust_code")
          @t_collect_lists = @t_collect_lists.joins("left join m_customs mc2 ON mc2.cust_kbn='#{G_CUST_KBN_ADMIN}' AND mc2.cust_code=mc.admin_code")
          @t_collect_lists = @t_collect_lists.joins("left join m_combos ON m_combos.class_1 = '#{G_MIKAISHU_CLASS_1}' AND m_combos.class_2=0 AND m_combos.class_code = t_collect_lists.mikaishu_code")
          @t_collect_lists = @t_collect_lists.joins("left join (select carrun_id, cust_kbn, cust_code, count(*) as memo_count from t_carrun_memos group by carrun_id, cust_kbn, cust_code) tcm on tcm.carrun_id=tc.id and tcm.cust_kbn=t_collect_lists.cust_kbn and tcm.cust_code=t_collect_lists.cust_code")
          @t_collect_lists = @t_collect_lists.joins("left join (select tcl.cust_kbn, tcl.cust_code from t_collect_lists tcl inner join t_carruns tc on tc.out_timing=tcl.out_timing and tc.car_code=tcl.car_code where tcl.out_timing>='#{params[:out_date].to_date}' and tcl.out_timing<'#{params[:out_date].to_date.tomorrow.strftime("%Y/%m/%d")}' and tc.route_code='#{params[:route_code]}' and tcl.cust_code<>'*' and tcl.finish_timing is not null group by tcl.cust_kbn, tcl.cust_code) acl on acl.cust_kbn=t_collect_lists.cust_kbn and acl.cust_code=t_collect_lists.cust_code")
          @iCount = 0
          if not @t_collect_details.nil?
            @t_collect_details.each do |t_collect_detail|
              @iCount = @iCount + 1
              @t_collect_lists = @t_collect_lists.joins("left join t_collect_details tcd" + @iCount.to_s + " on tcd" + @iCount.to_s + ".out_timing=t_collect_lists.out_timing and tcd" + @iCount.to_s + ".car_code=t_collect_lists.car_code and tcd" + @iCount.to_s + ".spot_no=t_collect_lists.spot_no and tcd" + @iCount.to_s + ".item_kbn=" + t_collect_detail.item_kbn.to_s)
            end
          end
          @t_collect_lists = @t_collect_lists.where("t_collect_lists.out_timing >= ? and t_collect_lists.out_timing < ? and t_collect_lists.car_code = ? and tc.route_code=?", params[:out_date].to_date, params[:out_date].to_date.tomorrow.strftime("%Y/%m/%d"), params[:car_code], params[:route_code])
          @t_collect_lists = @t_collect_lists.group("t_collect_lists.cust_kbn, t_collect_lists.cust_code, t_collect_lists.finish_timing")
          @t_collect_lists = @t_collect_lists.joins("left join (select tcl.cust_kbn, tcl.cust_code, count(*) as cust_count from t_collect_lists tcl inner join t_carruns tc on tc.out_timing=tcl.out_timing and tc.car_code=tcl.car_code where tc.out_timing>='#{params[:out_date].to_date}' and tc.out_timing<'#{params[:out_date].to_date.tomorrow.strftime("%Y/%m/%d")}' and tc.car_code='#{params[:car_code]}' and tc.route_code='#{params[:route_code]}' and tcl.finish_timing is not null group by tcl.cust_kbn, tcl.cust_code) cnt on cnt.cust_kbn=t_collect_lists.cust_kbn and cnt.cust_code=t_collect_lists.cust_code")
          @t_collect_lists = @t_collect_lists.where("t_collect_lists.finish_timing is not null or (t_collect_lists.finish_timing is null and cnt.cust_count is null)")
          @t_collect_lists = @t_collect_lists.select("t_collect_lists.cust_kbn, t_collect_lists.cust_code, t_collect_lists.finish_timing, t_collect_lists.mikaishu_count, t_collect_lists.mikaishu_code, tc.id as carrun_id, m_combos.class_name as mikaishu_name, t_collect_lists.spot_no, t_collect_lists.spot_no as tree_no, t_collect_lists.cust_name, t_collect_lists.latitude, t_collect_lists.longitude, mc.addr_1, mc.addr_2, mc.memo, mc2.cust_name as admin_name, mc2.tel_no, mc2.email"+@strselect.to_s)
          @t_collect_lists = @t_collect_lists.order("t_collect_lists.spot_no, t_collect_lists.id")
        end
        @t_collect_lists.each do |t_collect_list|
          @arrDetail = [t_collect_list.spot_no.to_s, t_collect_list.cust_code.to_s,t_collect_list.cust_name.to_s,t_collect_list.addr_1.to_s+t_collect_list.addr_2.to_s,t_collect_list.memo.to_s,t_collect_list.admin_name.to_s,t_collect_list.tel_no.to_s,t_collect_list.email.to_s,t_collect_list.finish_timing.try(:strftime, "%H:%M:%S")]
          if @iCount > 0
            for num in 1..@iCount
              @arrDetail[num+8] = t_collect_list["item_count_"+num.to_s]
            end
          end
          @arrDetail[@iCount+9] = t_collect_list.mikaishu_count.to_s
          @arrDetail[@iCount+10] = t_collect_list.mikaishu_name.to_s
          ws.add_row(@arrDetail, :types => [:integer, :string, :string, :string, :string, :string, :string, :string], :style=>detail_style)
        end

        # 横幅
        ws.column_widths *@arrWidth
        
        #ウィンドウ固定
        ws.sheet_view.pane do |pane|
          pane.top_left_cell = "B11"
          pane.state = :frozen_split
          pane.y_split = 10
          pane.x_split = 0
          pane.active_pane = :bottom_left
        end
      end
    end
    if (/MSIE/ =~ request.user_agent) || (/Trident/ =~ request.user_agent) || (/Edge/ =~ request.user_agent)
      send_data(pkg.to_stream.read, 
        :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        :filename => "運転日報.xlsx".encode('Shift_JIS'))
    else
      send_data(pkg.to_stream.read, 
        :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        :filename => "運転日報.xlsx")
    end
    api_log_hists(201, 5, "")
  end
  
  def ajax
    #マーカー再描画
    if params[:marker_flg]
      @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
      northeast_lat = params[:northeast_lat][0]
      southwest_lat = params[:southwest_lat][0]
      northeast_lng = params[:northeast_lng][0]
      southwest_lng = params[:southwest_lng][0]
      carrun_id = params[:carrun_id][0]
      
      @mikaishu_codes = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_MIKAISHU_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
      @m_customs = MCustom
      if carrun_id.blank?
        @m_customs = @m_customs.where("m_customs.delete_flg=0 AND m_customs.cust_kbn='#{G_CUST_KBN_STATION}' AND m_customs.latitude<='#{northeast_lat}' AND m_customs.latitude>='#{southwest_lat}' AND m_customs.longitude<='#{northeast_lng}' AND m_customs.longitude>='#{southwest_lng}'")
        @m_customs = @m_customs.select("m_customs.id, m_customs.cust_kbn, m_customs.cust_code, m_customs.cust_name, m_customs.latitude, m_customs.longitude, '#{@mikaishu_codes}' AS mikaishu_codes, case when (m_customs.start_date is null OR m_customs.start_date<='#{@now_date}') AND (m_customs.end_date is null OR m_customs.end_date>='#{@now_date}') then '' else 'lightgrey' end as bgcolor").order("m_customs.cust_code")
      else
        @m_customs = @m_customs.joins("left join t_carruns tc on tc.id=#{carrun_id}").joins("left join t_collect_lists cl on cl.out_timing=tc.out_timing and cl.car_code=tc.car_code and cl.cust_kbn=m_customs.cust_kbn and cl.cust_code=m_customs.cust_code")
        @m_customs = @m_customs.where("m_customs.delete_flg=0 AND m_customs.cust_kbn='#{G_CUST_KBN_STATION}' AND ((cl.out_timing is not null AND cl.latitude<='#{northeast_lat}' AND cl.latitude>='#{southwest_lat}' AND cl.longitude<='#{northeast_lng}' AND cl.longitude>='#{southwest_lng}') OR (cl.out_timing is null AND m_customs.latitude<='#{northeast_lat}' AND m_customs.latitude>='#{southwest_lat}' AND m_customs.longitude<='#{northeast_lng}' AND m_customs.longitude>='#{southwest_lng}'))")
        @m_customs = @m_customs.select("m_customs.id, m_customs.cust_kbn, m_customs.cust_code, case when cl.id is null then m_customs.cust_name else cl.cust_name end as cust_name, case when cl.id is null then m_customs.latitude else cl.latitude end as latitude, case when cl.id is null then m_customs.longitude else cl.longitude end as longitude, '#{@mikaishu_codes}' AS mikaishu_codes, case when (m_customs.start_date is null OR m_customs.start_date<='#{@now_date}') AND (m_customs.end_date is null OR m_customs.end_date>='#{@now_date}') then '' else 'lightgrey' end as bgcolor").order("m_customs.cust_code")
      end

      # 荷下先
      @unloads = MCustom.joins("left join m_collect_industs mci on mci.cust_kbn=m_customs.cust_kbn and mci.cust_code=m_customs.cust_code")
      @unloads = @unloads.joins("left join m_combos indust on indust.class_1='#{G_ITEM_CLASS_1}' and indust.class_code=mci.indust_kbn")
      @unloads = @unloads.joins("left join m_combos unit on unit.class_1='#{G_UNIT_CLASS_1}' and unit.class_code=mci.unit_kbn")
      @unloads = @unloads.where("m_customs.delete_flg=0 AND m_customs.cust_kbn='#{G_CUST_KBN_UNLOAD}' AND m_customs.latitude<='#{northeast_lat}' AND m_customs.latitude>='#{southwest_lat}' AND m_customs.longitude<='#{northeast_lng}' AND m_customs.longitude>='#{southwest_lng}'")
      @unloads = @unloads.select("m_customs.id, m_customs.cust_kbn, m_customs.cust_code, m_customs.cust_name, m_customs.latitude, m_customs.longitude, group_concat(DISTINCT CONCAT('{indust_kbn:',mci.indust_kbn,',unit_kbn:',mci.unit_kbn,',indust_name:''',indust.class_name,''',unit_name:''',unit.class_name,'''}') ORDER BY mci.tree_no, mci.indust_kbn, mci.id SEPARATOR ',') as indust")
      @unloads = @unloads.group("m_customs.cust_code, m_customs.id").order("m_customs.cust_code, m_customs.id")
      @iCount = 0
      @unloads.each do |unload|
        @unloads[@iCount].indust = ERB::Util.url_encode(unload.indust)
        @iCount = @iCount + 1
      end
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
