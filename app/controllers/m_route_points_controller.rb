class MRoutePointsController < ApplicationController

  before_action :authenticate_user!
  before_action :set_map_key
  before_action :set_zenrin_map_key
  before_action :set_search_params, only: [:ajax]
  require 'nkf'

  # GET /m_route_points
  # GET /m_route_points.json
  def index
    routecode = params[:routecode]
    @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
    @m_route_areas = MRouteArea.where("route_code=?", params[:routecode])
    @m_route1 = MRoute.joins("left join m_combos mc on mc.class_1='#{G_COLOR_PATTERN_CLASS_1}' and mc.class_2=0 and mc.class_code=m_routes.area_color").where("route_code = ?", params[:routecode]).select("m_routes.*, mc.value as area_color_value").first
    
    @m_customs = MCustom.joins("INNER JOIN m_route_points rp ON rp.cust_kbn=m_customs.cust_kbn AND rp.cust_code=m_customs.cust_code AND rp.route_code='#{routecode}'")
    @m_customs = @m_customs.joins("LEFT JOIN m_customs admin on admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code")
    @m_customs = @m_customs.joins("cross join (select @i:=0) as cnt")
    @m_customs = @m_customs.where("m_customs.delete_flg=0 AND m_customs.cust_kbn='#{G_CUST_KBN_STATION}' AND m_customs.latitude is not null AND m_customs.longitude is not null")
    @m_customs = @m_customs.select("m_customs.cust_code, m_customs.cust_name, m_customs.addr_1, m_customs.addr_2, m_customs.latitude, m_customs.longitude, m_customs.admin_code, m_customs.tel_no, m_customs.email, admin.cust_name as admin_name, rp.route_code, rp.tree_no, case when (m_customs.start_date is null OR m_customs.start_date<='#{@now_date}') AND (m_customs.end_date is null OR m_customs.end_date>='#{@now_date}') then '' else 'lightgrey' end as bgcolor, @i:=@i+1 AS seq_id")
    @m_customs = @m_customs.order("rp.tree_no, m_customs.cust_code")
    @m_route_points = @m_customs
    
    @m_route_point = MRoutePoint.joins("INNER JOIN m_customs c ON c.cust_kbn=m_route_points.cust_kbn AND c.cust_code = m_route_points.cust_code").where("m_route_points.route_code=?", routecode).select("c.latitude, c.longitude").order("m_route_points.tree_no").first
    @use_contents = MCombo.where("class_1='#{G_USE_CONTENT_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }

    @recommend_latlng = ""
    @m_route_recommends = MRouteRecommend.where("route_code=?", routecode).select("latlng").order("priority asc, id asc").first
    if not @m_route_recommends.nil?
      @recommend_latlng = @m_route_recommends.latlng.to_s
    end
    
    if @m_route_point.nil?
      @def_lat = A_DEF_LATITUDE
      @def_lng = A_DEF_LONGITUDE
    else
      @def_lat = @m_route_point.latitude
      @def_lng = @m_route_point.longitude
    end
    if params[:lat_del]
      @def_lat = params[:lat_del]
      @def_lng = params[:lng_del]
      @def_zoom = params[:zoom_del]
    else
      @def_zoom = 18
    end
    @def_address = A_DEF_ADDRESS

    @admin_types = MCombo.where("class_1='#{G_ADMIN_TYPE_CLASS_1}' AND class_2=0").order("class_code")
    render
  end

  def show
    require 'axlsx'
    # Excel書き出し
    pkg = Axlsx::Package.new
    pkg.workbook do |wb|
      setup = {:orientation => :landscape, :paper_size => 9, :fit_to_page=>true}
      header_footer = {:different_first => false, :odd_header=>'収集区内ステーション一覧',:odd_footer=>'page : &P/&N'}
      wb.add_worksheet(:name => '収集区内ステーション一覧', :page_setup => setup, :header_footer=>header_footer) do |ws|   # シート名の指定は省略可

        m_route = MRoute.where("m_routes.id=?",params[:id]).first

        header_style = ws.styles.add_style :sz => 9, :border => {:style => :thin, :color => "FF333333"}
        dheader_style = ws.styles.add_style :sz => 9, :bg_color => "C0C0C0", :border => {:style => :thin, :color => "FF333333"}
        detail_style = ws.styles.add_style :sz => 9, :border => {:style => :thin, :color => "FF333333"}
        # ヘッダ行
        ws.add_row()
        ws.add_row(['収集区コード',nil, m_route.route_code], :types => [:string, :string, :string], :style=>[dheader_style,dheader_style,header_style,header_style], :bg_color=>[:bg_color=>"C0C0C0"])
        ws.add_row(['収集区名称',nil, m_route.route_name], :types => [:string, :string, :string], :style=>[dheader_style,dheader_style,header_style,header_style])
        ws.add_row()
        ws.merge_cells "A2:B2"
        ws.merge_cells "A3:B3"
        
        # 明細ヘッダ
        @arrHeader = ['SEQ', 'ｽﾃｰｼｮﾝID','ステーション名','住所','備考','管理者名']
        @arrWidth = [5, 7, 25, 50, 50, 14]
        ws.add_row(@arrHeader, :style=>dheader_style)
        
        @m_route_points = MRoutePoint.joins("left join m_customs mc on mc.cust_kbn=m_route_points.cust_kbn and mc.cust_code=m_route_points.cust_code")
        @m_route_points = @m_route_points.joins("LEFT JOIN m_customs admin on admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=mc.admin_code")
        @m_route_points = @m_route_points.where("route_code=?", m_route.route_code)
        @m_route_points = @m_route_points.select("m_route_points.*, mc.cust_name, rtrim(concat(ifnull(mc.addr_1,''), ' ', ifnull(mc.addr_2,''))) as addr, mc.memo, admin.cust_name as admin_name")
        @m_route_points = @m_route_points.order("m_route_points.tree_no, m_route_points.id")
        @m_route_points.each do |m_route_point|
          ws.add_row([m_route_point.tree_no.to_s, m_route_point.cust_code.to_s, m_route_point.cust_name.to_s, m_route_point.addr.to_s, m_route_point.memo.gsub(/(\r\n|\r|\n)/, "\n").to_s, m_route_point.admin_name.to_s], :types => [:integer, :string, :string, :string, :string, :string], :style=>detail_style)
        end
        # 横幅
        ws.column_widths *@arrWidth
        
        #ウィンドウ固定
        ws.sheet_view.pane do |pane|
          pane.top_left_cell = "A6"
          pane.state = :frozen_split
          pane.y_split = 5
          pane.x_split = 0
          pane.active_pane = :bottom_left
        end
      end
    end
    if (/MSIE/ =~ request.user_agent) || (/Trident/ =~ request.user_agent) || (/Edge/ =~ request.user_agent)
      send_data(pkg.to_stream.read, 
        :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        :filename => "収集区内ステーション一覧.xlsx".encode('Shift_JIS'))
    else
      send_data(pkg.to_stream.read, 
        :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        :filename => "収集区内ステーション一覧.xlsx")
    end
    api_log_hists(103, 5, "")
  end

  # POST /m_route_points
  # POST /m_route_points.json
  def ajax
    if params[:cnt_no]
      # 更新処理
      
      # トランザクション処理
      begin
        ActiveRecord::Base.transaction do
          custcode = params[:cust_code]
          MRoutePoint.destroy_all(route_code: params[:routecode])
          params[:cnt_no].to_i.times do |i|
            if not custcode[i].nil?
              @m_route_point = MRoutePoint.create!(:route_code => params[:routecode], :tree_no=> i+1, :cust_kbn => G_CUST_KBN_STATION, :cust_code => custcode[i])
              logger.fatal(current_user.user_id.to_s + "_m_route_points_upd")
            end
          end
        end
        @m_route = MRoute.where("route_code=?", params[:routecode]).first
        change_comment = @m_route.route_code.to_s + ":" + @m_route.route_name.to_s
        api_log_hists(103, 2, change_comment)
        #redirect_to ({:action => "index", :routecode => params[:routecode]}), notice: '並び順の更新が完了しました。'
        redirect_to m_route_points_url.to_s+@search_params.to_s + "&routecode="+params[:routecode].to_s, notice: "並び順の更新が完了しました。"
      rescue => e
        #redirect_to ({:action => "index", :routecode => params[:routecode]}), alert: '※並び順の更新に失敗しました。'
        redirect_to m_route_points_url.to_s+@search_params.to_s + "&routecode="+params[:routecode].to_s, alert: "※並び順の更新に失敗しました。"
      end
    end
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
                  @tree_no = MRoutePoint.where("route_code=?", params[:route_code_new][0]).maximum(:tree_no).to_i + 1
                  @m_route_point = MRoutePoint.new(:route_code => params[:route_code_new][0], :tree_no=> @tree_no, :cust_kbn => G_CUST_KBN_STATION, :cust_code => @custcode)
                  @m_route_point.save
                  @m_route = MRoute.where("route_code=?", params[:route_code_new][0]).first
                  change_comment = @m_route.route_code.to_s + ":" +  @m_route.route_name.to_s + "　" + @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
                  api_log_hists(103, 1, change_comment)
                  logger.fatal(current_user.user_id.to_s + "_m_route_points_upd")
                else
                  change_comment = @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
                  api_log_hists(103, 1, change_comment)
                end
                #bgcolor用
                if params[:start_date_new][0].blank? || params[:start_date_new][0]<=Date.today.try(:strftime, "%Y/%m/%d")
                  @bgcolor = ""
                else
                  @bgcolor = "lightgrey"
                end
                @ajaxflg = 2
              else
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
    if params[:delete_flg]=="1"
      # トランザクション処理
      begin
        ActiveRecord::Base.transaction do
          #収集区内削除
          @m_route_point_dlt = MRoutePoint.where("route_code=? AND cust_code=?", params[:routecode],  params[:cust_code]).first
          @m_route_point_dlt.destroy
          #tree_no更新
          @tree_no = 0
          @m_route_points = MRoutePoint.where("route_code=?", params[:routecode]).order("tree_no, id")
          @m_route_points.each do |m_route_point|
            @tree_no = @tree_no + 1
            m_route_point.update!(:tree_no => @tree_no)
          end
        end
        
        @m_route = MRoute.where("route_code=?", params[:routecode]).first
        @m_custom = MCustom.where("cust_kbn=? and cust_code=?", G_CUST_KBN_STATION, params[:cust_code]).first
        change_comment = @m_route.route_code.to_s + ":" +  @m_route.route_name.to_s + "　" + @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
        api_log_hists(103, 3, change_comment)
        logger.fatal(current_user.user_id.to_s + "_m_route_points_add")
        @ajaxflg = 3
      rescue => e
        @ajaxflg = -3
      end

    end
    if params[:add_flg]=="1"
      # トランザクション処理
      begin
        ActiveRecord::Base.transaction do
          @tree_no = MRoutePoint.where("route_code=?", params[:routecode]).maximum(:tree_no).to_i + 1
          @m_route_point_add = MRoutePoint.create!(:route_code => params[:routecode], :tree_no=> @tree_no, :cust_kbn => G_CUST_KBN_STATION, :cust_code => params[:cust_code])
        end
        
        @m_route = MRoute.where("route_code=?", params[:routecode]).first
        @m_custom = MCustom.where("cust_kbn=? and cust_code=?", G_CUST_KBN_STATION, params[:cust_code]).first
        change_comment = @m_route.route_code.to_s + ":" +  @m_route.route_name.to_s + "　" + @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
        api_log_hists(103, 1, change_comment)
        logger.fatal(current_user.user_id.to_s + "_m_route_points_upd")
        @ajaxflg = 3
      rescue => e
        @ajaxflg = -3
      end
    end
    #マーカー再描画
    if params[:marker_flg]
      @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
      routecode = params[:routecode_marker][0]
      northeast_lat = params[:northeast_lat][0]
      southwest_lat = params[:southwest_lat][0]
      northeast_lng = params[:northeast_lng][0]
      southwest_lng = params[:southwest_lng][0]

      @m_customs = MCustom.joins("left join m_route_points rp ON rp.cust_kbn=m_customs.cust_kbn AND rp.cust_code=m_customs.cust_code AND rp.route_code='#{routecode}'")
      @m_customs = @m_customs.joins("left join m_customs admin ON admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code")
      @m_customs = @m_customs.joins("left join m_combos type on type.class_1='#{G_ADMIN_TYPE_CLASS_1}' and type.class_2=0 and type.class_code=admin.admin_type")
      @m_customs = @m_customs.joins("left join (select min(mr.route_code) as route_code, mrp.cust_kbn, mrp.cust_code from m_routes mr inner join m_route_points mrp on mrp.route_code=mr.route_code where mr.delete_flg=0 and mrp.cust_kbn='#{G_CUST_KBN_STATION}' group by mrp.cust_kbn, mrp.cust_code) mrp on mrp.cust_kbn=m_customs.cust_kbn and mrp.cust_code=m_customs.cust_code")
      @m_customs = @m_customs.joins("left join m_routes mr on mr.route_code=mrp.route_code")
      @m_customs = @m_customs.joins("left join m_combos clr on clr.class_1='#{G_COLOR_PATTERN_CLASS_1}' and clr.class_2=0 and clr.class_code=mr.area_color")
      @m_customs = @m_customs.joins("cross join (select @i:=0) as cnt")
      @m_customs = @m_customs.where("m_customs.delete_flg=0 AND m_customs.cust_kbn='#{G_CUST_KBN_STATION}' AND m_customs.latitude<='#{northeast_lat}' AND m_customs.latitude>='#{southwest_lat}' AND m_customs.longitude<='#{northeast_lng}' AND m_customs.longitude>='#{southwest_lng}'")
      @m_customs = @m_customs.select("m_customs.id, m_customs.cust_kbn, m_customs.cust_code, m_customs.cust_name, m_customs.addr_1, m_customs.addr_2, m_customs.latitude, m_customs.longitude, m_customs.admin_code, admin.cust_name as admin_name, admin.tel_no as admin_tel, admin.email as admin_email, type.value as type_value, rp.route_code, rp.tree_no, case when (m_customs.start_date is null OR m_customs.start_date<='#{@now_date}') AND (m_customs.end_date is null OR m_customs.end_date>='#{@now_date}') then '' else 'lightgrey' end as bgcolor, '' AS route_memo, clr.value2 as marker_color, @i:=@i+1 AS seq_id")
      @m_customs = @m_customs.order("rp.tree_no, m_customs.cust_code")

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
