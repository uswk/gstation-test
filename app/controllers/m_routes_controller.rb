class MRoutesController < ApplicationController
 
  before_action :authenticate_user!
  before_action :set_map_key
  before_action :set_zenrin_map_key
  before_action :set_itaku, :only => [:index]
  before_action :set_hold_params, only: [:show, :edit, :new, :create, :update]
  before_action :set_search_params, only: [:index, :create, :update, :destroy]

  # GET /m_routes
  def index
    if params[:hold_params].blank?
      @routecode = params[:search].blank? ? "" : params[:search][:route_code]
      @routename = params[:search].blank? ? "" : params[:search][:route_name]
      @itakucode = params[:search].blank? ? "" : params[:search][:itaku]
      @deleteflg = params[:search].blank? ? 0 : params[:search][:delete]
      @blndelete = params[:search].blank? ? false : params[:search][:delete]=="1" ? true : false
      @bgcolor_td = params[:search].blank? ? "" : params[:search][:delete]=="1" ? "bgcolor=lightgrey" : ""
    else
      @routecode = params[:search_routecode].blank? ? "" : params[:search_routecode]
      @routename = params[:search_routename].blank? ? "" : params[:search_routename]
      @itakucode = params[:search_itaku].blank? ? "" : params[:search_itaku]
      @deleteflg = params[:search_delete].blank? ? 0 : params[:search_delete]
      @blndelete = params[:search_delete].blank? ? false : params[:search_delete]=="1" ? true : false
      @bgcolor_td = params[:search_delete].blank? ? "" : params[:search_delete]=="1" ? "bgcolor=lightgrey" : ""
    end
    strwhere = @deleteflg
    strwhere = "m_routes.delete_flg='#{@deleteflg}'"
    # 収集区コード
    if @routecode != ""
      strwhere = strwhere + " and m_routes.route_code='#{@routecode}'"
    end
    # 収集区名称
    if @routename != ""
      strwhere = strwhere + " and m_routes.route_name like '%#{@routename}%'"
    end
    # 委託会社
    if not current_user.itaku_code.blank?
      strwhere = strwhere + " and mrr.itaku_code = '#{current_user.itaku_code}'"
    else
      if @itakucode != ""
        strwhere = strwhere + " and mrr.itaku_code = '#{@itakucode}'"
      end
    end
    @m_routes = MRoute.joins("left join (select route_code, itaku_code, max(itaku.cust_name) as itaku_name from m_route_rundates mrr2 left join m_customs itaku on itaku.cust_kbn='#{G_CUST_KBN_GYOSHA}' and itaku.cust_code=mrr2.itaku_code where itaku_code is not null and itaku_code<>'' group by route_code, itaku_code) mrr2 on mrr2.route_code=m_routes.route_code")
    if (not current_user.itaku_code.blank?) || (@itakucode != "")
      @m_routes = @m_routes.joins("left join (select route_code, itaku_code from m_route_rundates group by route_code, itaku_code) mrr on mrr.route_code=m_routes.route_code")
    end
    @m_routes = @m_routes.joins("left join (select route_code, count(route_code) as itaku_count from m_route_rundates where itaku_code<>'#{current_user.itaku_code.to_s}' group by route_code) ic on ic.route_code=m_routes.route_code")
    @m_routes = @m_routes.select("m_routes.*, ic.itaku_count, group_concat(DISTINCT concat(mrr2.itaku_name) ORDER BY mrr2.route_code, mrr2.itaku_code SEPARATOR ' 、') as itaku_name")
    @m_routes = @m_routes.page(params[:page]).per("#{G_DEF_PAGE_PER}").where("#{strwhere}")
    @m_routes = @m_routes.group("m_routes.route_code").order("m_routes.route_code, m_routes.id")

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /m_routes/1
  def show
    @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
    
    @m_route = MRoute.joins("left join m_customs mc on mc.cust_kbn='#{G_CUST_KBN_GYOSHA}' and mc.cust_code=m_routes.itaku_code")
    @m_route = @m_route.joins("left join m_combos clr on clr.class_1='#{G_COLOR_PATTERN_CLASS_1}' and clr.class_2=0 and clr.class_code=m_routes.area_color")
    @m_route = @m_route.where("m_routes.id=?", params[:id]).select("m_routes.*, mc.cust_name as itaku_name, clr.class_name as area_color_name, clr.value2 as marker_color").first
    if not current_user.itaku_code.blank?
      strwhere = " and m_route_rundates.itaku_code = '#{current_user.itaku_code}'"
    end
    @m_route_rundates = MRouteRundate.joins("LEFT JOIN m_combos c ON c.class_1='#{G_WEEK_CLASS_1}' AND c.class_2=0 AND c.class_code=m_route_rundates.run_week")
    @m_route_rundates = @m_route_rundates.joins("LEFT JOIN m_combos c2 ON c2.class_1='#{G_YOBI_CLASS_1}' AND c2.class_2=0 AND c2.class_code=m_route_rundates.run_yobi")
    @m_route_rundates = @m_route_rundates.joins("LEFT JOIN m_combos c3 ON c3.class_1='#{G_ITEM_CLASS_1}' AND c3.class_2=0 AND c3.class_code=m_route_rundates.item_kbn")
    @m_route_rundates = @m_route_rundates.joins("LEFT JOIN m_combos c4 ON c4.class_1='#{G_UNIT_CLASS_1}' AND c4.class_2=0 AND c4.class_code=m_route_rundates.unit_kbn")
    @m_route_rundates = @m_route_rundates.joins("LEFT JOIN m_customs mc on mc.cust_kbn='#{G_CUST_KBN_GYOSHA}' and mc.cust_code=m_route_rundates.itaku_code")
    @m_route_rundates = @m_route_rundates.where("m_route_rundates.route_code=?"+strwhere.to_s, @m_route.route_code).select("c.class_name AS run_week_name, c2.class_name AS run_yobi_name, c3.class_name AS item_name, c4.class_name as unit_name, mc.cust_name as itaku_name").order("m_route_rundates.tree_no")
    
    @m_route_areas = MRouteArea.where("route_code=?", @m_route.route_code)
    @m_route1 = MRoute.joins("left join m_combos mc on mc.class_1='#{G_COLOR_PATTERN_CLASS_1}' and mc.class_2=0 and mc.class_code=m_routes.area_color").where("route_code = ?", @m_route.route_code).select("m_routes.*, mc.value as area_color_value").first
    
    @m_route_points = MRoutePoint.joins("inner join m_customs mc on mc.cust_kbn=m_route_points.cust_kbn and mc.cust_code=m_route_points.cust_code")
    @m_route_points = @m_route_points.joins("left join m_customs admin ON admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=mc.admin_code")
    @m_route_points = @m_route_points.joins("left join m_combos type on type.class_1='#{G_ADMIN_TYPE_CLASS_1}' and type.class_2=0 and type.class_code=admin.admin_type")
    @m_route_points = @m_route_points.joins("cross join (select @i:=0) as cnt")
    @m_route_points = @m_route_points.where("m_route_points.route_code=?", @m_route.route_code)
    @m_route_points = @m_route_points.select("m_route_points.*, mc.id as custom_id, mc.cust_name, mc.addr_1, mc.addr_2, mc.latitude, mc.longitude, mc.admin_code, admin.cust_name as admin_name, admin.tel_no as admin_tel, admin.email as admin_email, type.value as type_value, case when (mc.start_date is null OR mc.start_date<='#{@now_date}') AND (mc.end_date is null OR mc.end_date>='#{@now_date}') then '' else 'lightgrey' end as bgcolor, @i:=@i+1 AS seq_id")
    @m_route_points = @m_route_points.order("m_route_points.tree_no, m_route_points.cust_kbn, m_route_points.cust_code")

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

  # GET /m_routes/new
  def new
    @m_route = MRoute.new
    @edit_type = params[:edit_type]
    @routecode = params[:routecode]
    strwhere = ""
    if @edit_type=='copy'
      @m_route_moto = MRoute.where("route_code=?", @routecode).first
      if not current_user.itaku_code.blank?
        strwhere = " and m_route_rundates.itaku_code='#{current_user.itaku_code}'"
      end
    end
    @m_route_rundates = MRouteRundate.where("m_route_rundates.route_code = ?" + strwhere.to_s, @routecode).select("m_route_rundates.*").order("m_route_rundates.tree_no")
    @run_weeks = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_WEEK_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @run_yobis = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_YOBI_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @item_kbns = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_ITEM_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @unit_kbns = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_UNIT_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @area_colors = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_COLOR_PATTERN_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @itaku_codes = MCustom.where("cust_kbn='#{G_CUST_KBN_GYOSHA}'").order("cust_code asc").map{|i| [i.cust_name, i.cust_code] }
    @action_form = 'create'

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /m_routes/1/edit
  def edit
    @m_route = MRoute.find(params[:id])
    @m_route_rundates = MRouteRundate.where("m_route_rundates.route_code = ?", @m_route.route_code).select("m_route_rundates.*").order("m_route_rundates.tree_no")
    @run_weeks = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_WEEK_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @run_yobis = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_YOBI_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @item_kbns = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_ITEM_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @unit_kbns = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_UNIT_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @area_colors = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_COLOR_PATTERN_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @itaku_codes = MCustom.where("cust_kbn='#{G_CUST_KBN_GYOSHA}'").order("cust_code asc").map{|i| [i.cust_name, i.cust_code] }
    @action_form = 'update'
    @edit_type = params[:edit_type]
    @routecode = params[:routecode]
  end

  # POST /m_routes
  def create
    params.permit!
    
    if params[:excel_output].to_s=="1"
      strwhere = " m_routes.delete_flg='#{params[:excel_delete_flg].to_s}'"
      #収集区コード
      if not params[:excel_route_code].blank?
        strwhere = strwhere + " and m_routes.route_code='#{params[:excel_route_code].to_s}'"
      end
      #収集区名
      if not params[:excel_route_name].blank?
        strwhere = strwhere + " and m_routes.route_name like '%#{params[:excel_route_name].to_s}%'"
      end
      # 委託会社
      if not current_user.itaku_code.blank?
        strwhere = strwhere + " and mrr.itaku_code = '#{current_user.itaku_code}'"
      else
        if not params[:excel_itaku_code].blank?
          strwhere = strwhere + " and mrr.itaku_code='#{params[:excel_itaku_code].to_s}'"
        end
      end
      
      # Excel書き出し
      require 'axlsx'
      pkg = Axlsx::Package.new
      pkg.workbook do |wb|
        wb.add_worksheet(:name => '収集区基本情報一覧') do |ws|   # シート名の指定は省略可
          # ヘッダ行
          header_style = ws.styles.add_style :bg_color => "C0C0C0", :border => {:style => :thin, :color => "FF333333"}
          ws.add_row(['収集区ｺｰﾄﾞ', '収集区名','ごみの種類ごとの数量入力','週','収集曜日','ごみ種類','単位','委託会社ｺｰﾄﾞ', '委託会社名'], :style=>header_style)
          # 横幅
          ws.column_widths(10, 30, 10, 10, 10, 20, 10, 10, 20)
          detail_style = ws.styles.add_style :border => {:style => :thin, :color => "FF333333"}
          
          
          @m_routes = MRoute.joins("left join m_route_rundates mrr on mrr.route_code=m_routes.route_code")
          @m_routes = @m_routes.joins("LEFT JOIN m_combos c ON c.class_1='#{G_WEEK_CLASS_1}' AND c.class_2=0 AND c.class_code=mrr.run_week")
          @m_routes = @m_routes.joins("LEFT JOIN m_combos c2 ON c2.class_1='#{G_YOBI_CLASS_1}' AND c2.class_2=0 AND c2.class_code=mrr.run_yobi")
          @m_routes = @m_routes.joins("LEFT JOIN m_combos c3 ON c3.class_1='#{G_ITEM_CLASS_1}' AND c3.class_2=0 AND c3.class_code=mrr.item_kbn")
          @m_routes = @m_routes.joins("LEFT JOIN m_combos c4 ON c4.class_1='#{G_UNIT_CLASS_1}' AND c4.class_2=0 AND c4.class_code=mrr.unit_kbn")
          @m_routes = @m_routes.joins("LEFT JOIN m_customs mc on mc.cust_kbn='#{G_CUST_KBN_GYOSHA}' and mc.cust_code=mrr.itaku_code")
          @m_routes = @m_routes.where("#{strwhere}")
          @m_routes = @m_routes.select("m_routes.route_code, m_routes.route_name, m_routes.use_item_flg, mrr.itaku_code, c.class_name AS run_week_name, c2.class_name AS run_yobi_name, c3.class_name AS item_name, c4.class_name as unit_name, mc.cust_name as itaku_name")
          @m_routes = @m_routes.order("m_routes.route_code, mrr.tree_no")
          @m_routes.each do |m_route|
            ws.add_row([m_route.route_code.to_s, m_route.route_name.to_s, m_route.use_item_flg==1 ? "する":"しない", m_route.run_week_name.to_s, m_route.run_yobi_name.to_s, m_route.item_name.to_s, m_route.unit_name.to_s, m_route.itaku_code.to_s, m_route.itaku_name.to_s], :types => [:string, :string, :string, :string, :string, :string, :string, :string, :string], :style=>detail_style)
          end
        end
      end
      if (/MSIE/ =~ request.user_agent) || (/Trident/ =~ request.user_agent) || (/Edge/ =~ request.user_agent)
        send_data(pkg.to_stream.read, 
          :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          :filename => "収集区基本情報一覧.xlsx".encode('Shift_JIS'))
      else
        send_data(pkg.to_stream.read, 
          :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          :filename => "収集区基本情報一覧.xlsx")
      end
      
      api_log_hists(101, 5, "")
    else
      #@run_weeks = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_WEEK_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
      #@run_yobis = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_YOBI_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
      #@item_kbns = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_ITEM_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
      #@unit_kbns = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_UNIT_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
      #@area_colors = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_COLOR_PATTERN_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
      #@itaku_codes = MCustom.where("cust_kbn='#{G_CUST_KBN_GYOSHA}'").order("cust_code asc").map{|i| [i.cust_name, i.cust_code] }

      # トランザクション処理
      begin
        ActiveRecord::Base.transaction do
          @m_route = MRoute.new(params[:m_route])
          @upd_flg = 1
          params[:cnt_no].to_i.times do |i|
            if not params[:run_yobi].nil?
              if not params[:run_yobi][i].nil?
                if params[:unit_kbn].nil?
                  @unit_kbn = nil
                else
                  @unit_kbn = params[:unit_kbn][i]
                end
                @m_route_rundate = MRouteRundate.new(:route_code => @m_route.route_code, :tree_no=> i+1, :run_week => params[:run_week][i], :run_yobi => params[:run_yobi][i], :item_kbn => params[:item_kbn][i], :itaku_code => params[:itaku_code][i], :unit_kbn => @unit_kbn)
                @m_route_rundate.save!
              end
            end
          end
          # ステーション情報とエリア情報をコピー
          if params[:edit_type]=='copy'
            # ステーション
            @m_route_points = MRoutePoint.where("route_code=?", params[:routecode])
            @m_route_points.each do |m_route_point|
              @m_route_point = MRoutePoint.new(:route_code => @m_route.route_code, :tree_no=> m_route_point.tree_no, :cust_kbn => m_route_point.cust_kbn, :cust_code => m_route_point.cust_code)
              @m_route_point.save!
            end
            # エリア
            @m_route_areas = MRouteArea.where("route_code=?", params[:routecode])
            @m_route_areas.each do |m_route_area| 
              @m_route_area = MRouteArea.new(:route_code => @m_route.route_code, :tree_no=> m_route_area.tree_no, :latlng => m_route_area.latlng)
              @m_route_area.save!
            end
            # 推奨ルート
            @m_route_recommends = MRouteRecommend.where("route_code=?", params[:routecode])
            @m_route_recommends.each do |m_route_recommend| 
              @m_route_recommend = MRouteRecommend.new(:route_code => @m_route.route_code, :priority=> m_route_recommend.priority, :latlng => m_route_recommend.latlng, :carrun_id => m_route_recommend.carrun_id, :latlng_origin => m_route_recommend.latlng_origin)
              @m_route_recommend.save!
            end
          end
          @m_route.save!
        end
        change_comment = @m_route.route_code.to_s + ":" + @m_route.route_name.to_s
        api_log_hists(101, 1, change_comment)
        redirect_to m_routes_url.to_s+"/"+@m_route.id.to_s+@search_params.to_s, notice: '追加処理が完了しました。'
      rescue => e
        redirect_back fallback_location: m_routes_path, alert: '※例外が発生したため、追加処理に失敗しました。'
      end
    end
  end

  # PATCH/PUT /m_routes/1
  def update
    # トランザクション処理
    begin
      ActiveRecord::Base.transaction do
        @m_route = MRoute.find(params[:id])
        MRouteRundate.where("route_code=?", @m_route.route_code).destroy_all
        params[:cnt_no].to_i.times do |i|
          if not params[:run_yobi].nil?
            if not params[:run_yobi][i].nil?
              if params[:unit_kbn].nil?
                @unit_kbn = nil
              else
                @unit_kbn = params[:unit_kbn][i]
              end
              @m_route_rundate = MRouteRundate.new(:route_code => @m_route.route_code, :tree_no=> i+1, :run_week => params[:run_week][i], :run_yobi => params[:run_yobi][i], :item_kbn => params[:item_kbn][i], :itaku_code => params[:itaku_code][i], :unit_kbn => @unit_kbn)
              @m_route_rundate.save!
            end
          end
        end
        @m_route.update(params[:m_route])
      end
      change_comment = @m_route.route_code.to_s + ":" + @m_route.route_name.to_s
      api_log_hists(101, 2, change_comment)
      redirect_to m_routes_url.to_s+"/"+@m_route.id.to_s+@search_params.to_s, notice: '更新作業が完了しました。'
    rescue => e
      redirect_back fallback_location: m_routes_path, alert: '※例外が発生したため、更新処理に失敗しました。'
    end
  end

  # DELETE /m_routes/1
  def destroy
    @m_route = MRoute.find(params[:id])
    if @m_route.delete_flg==1
      @m_route.update(:delete_flg => 0)
      message_txt = "復活作業が完了しました。"
      change_type = 8
    else
      @m_route.update(:delete_flg => 1)
      message_txt = "削除作業が完了しました。"
      change_type = 3
    end
    respond_to do |format|
      change_comment = @m_route.route_code.to_s + ":" + @m_route.route_name.to_s
      api_log_hists(101, change_type, change_comment)
      format.html { redirect_to m_routes_url.to_s+@search_params.to_s, notice: message_txt }
    end
  end
  
  private
  
    def set_itaku
      #委託会社プルダウン用
      @itaku_codes = MCustom.where("cust_kbn=5 and delete_flg=0").order("cust_code asc").map{|i| [i.cust_code.to_s + ':' + i.cust_name.to_s, i.cust_code] }
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
