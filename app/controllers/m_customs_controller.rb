class MCustomsController < ApplicationController

  before_action :authenticate_user!
  before_action :set_map_key
  before_action :set_zenrin_map_key
  before_action :set_hold_params, only: [:show, :edit, :new, :create, :update]
  before_action :set_search_params, only: [:index, :create, :update, :destroy]
  before_action :set_m_custom, only: %i[show edit update destroy]
  before_action :load_combo_options, only: %i[new edit create update]

  # GET /m_customs
  # GET /m_customs.json
  def index
    @def_lat = A_DEF_LATITUDE;
    @def_lng = A_DEF_LONGITUDE;
    
    if params[:hold_params].blank?
      @custcode = params[:search].blank? ? "" : params[:search][:cust_code]
      @custname = params[:search].blank? ? "" : params[:search][:cust_name]
      @custaddr = params[:search].blank? ? "" : params[:search][:cust_addr]
      @custadmin = params[:search].blank? ? "" : params[:search][:cust_admin]
      @routecode = params[:search].blank? ? "" : params[:search][:route_code]
      @custpage = params[:search].blank? ? G_CUSTOM_PAGE_PER : params[:search][:cust_page]
      @deleteflg = params[:search].blank? ? 0 : params[:search][:delete]
      @blndelete = params[:search].blank? ? false : params[:search][:delete]=="1" ? true : false
    else
      @custcode = params[:search_custcode].blank? ? "" : params[:search_custcode]
      @custname = params[:search_custname].blank? ? "" : params[:search_custname]
      @custaddr = params[:search_custaddr].blank? ? "" : params[:search_custaddr]
      @custadmin = params[:search_custadmin].blank? ? "" : params[:search_custadmin]
      @routecode = params[:search_routecode].blank? ? "" : params[:search_routecode]
      @custpage = params[:search_custpage].blank? ? G_CUSTOM_PAGE_PER : params[:search_custpage]
      @deleteflg = params[:search_delete].blank? ? 0 : params[:search_delete]
      @blndelete = params[:search_delete].blank? ? false : params[:search_delete]=="1" ? true : false
    end
    @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
    strwhere = "m_customs.delete_flg='#{@deleteflg}'"
    strwhere = strwhere + " and m_customs.cust_kbn='#{G_CUST_KBN_STATION}'"
    # ｽﾃｰｼｮﾝｺｰﾄﾞ
    if @custcode != ""
      strwhere = strwhere + " and m_customs.cust_code='#{@custcode}'"
    end
    # ステーション名
    if @custname != ""
      strwhere = strwhere + " and m_customs.cust_name like '%#{@custname}%'"
    end
    # 住所
    if @custaddr != ""
      strwhere = strwhere + " and m_customs.addr_1 like '%#{@custaddr}%'"
    end
    # 管理者名
    if @custadmin != ""
      strwhere = strwhere + " and admin.cust_name like '%#{@custadmin}%'"
    end
    # 収集区
    if @routecode != ""
      if @routecode.to_s=="未設定"
        strwhere = strwhere + " and mrp.route_code is null"
      else
        strwhere = strwhere + " and mrp.route_code='#{@routecode}'"
      end
    end
    
    if current_user.authority==9
      custom_select = ",-5 as window_id"
    else
      custom_select = ",0 as window_id"
    end
    @m_customs = MCustom
    if @routecode != ""
      @m_customs = @m_customs.joins("left join m_route_points mrp on mrp.cust_kbn=m_customs.cust_kbn and mrp.cust_code=m_customs.cust_code")
    end
    @m_customs = @m_customs.joins("LEFT JOIN m_customs admin ON admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code")
    @m_customs = @m_customs.joins("left join m_combos type on type.class_1='#{G_ADMIN_TYPE_CLASS_1}' and type.class_2=0 and type.class_code=admin.admin_type")
    @m_customs = @m_customs.where("#{strwhere}").select("m_customs.*, admin.cust_name as admin_name, admin.tel_no as admin_tel, admin.email as admin_email, type.value as type_value, case when (m_customs.start_date is null OR m_customs.start_date<='#{@now_date}') AND (m_customs.end_date is null OR m_customs.end_date>='#{@now_date}') AND m_customs.delete_flg=0 then '' else 'lightgrey' end as bgcolor, '' as route_memo, '' as marker_color " + custom_select.to_s)
    @m_customs = @m_customs.page(params[:page]).per("#{@custpage}").order("cust_code, id")
    # 吹き出し内収集地区と収集曜日用
    @iCount = 0
    @m_customs.each do |m_custom|
      @memo = ""
      @m_route = MRoute.joins("inner join m_route_points mrp on mrp.route_code=m_routes.route_code").where("m_routes.delete_flg=0 and mrp.cust_kbn=? and mrp.cust_code=?", m_custom.cust_kbn, m_custom.cust_code).joins("left join m_combos clr on clr.class_1='#{G_COLOR_PATTERN_CLASS_1}' and clr.class_2=0 and clr.class_code=m_routes.area_color").select("clr.value2 as marker_color").order("m_routes.route_code, m_routes.id").first
      m_custom.marker_color = @m_route.nil? ? '' : @m_route.marker_color.to_s
      if @iCount==0
        @def_lat = m_custom.latitude.to_s
        @def_lng = m_custom.longitude.to_s
      end
      
      @iCount = @iCount + 1
    end

    @m_route_areas = MRouteArea.joins("INNER JOIN m_routes r ON r.route_code=m_route_areas.route_code").where("m_route_areas.latlng is not null and r.delete_flg=0").select("m_route_areas.*,r.route_name")

    # 収集区
    routewhere = ""
    if current_user.itaku_code.blank?
      routewhere = "m_routes.delete_flg = 0"
    else
      routewhere = "m_routes.delete_flg = 0 and mrr.itaku_code = '#{current_user.itaku_code}'"
    end
    @route_codes = MRoute.joins("left join m_route_rundates mrr on mrr.route_code=m_routes.route_code")
    @route_codes = @route_codes.where("#{routewhere}").group("m_routes.route_code, m_routes.route_name").order("m_routes.route_code asc").map{|i| [i.route_code.to_s + ':' + i.route_name.to_s, i.route_code] }
    @route_codes = @route_codes + ['未設定']

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @m_customs }
    end
  end

  # GET /m_customs/1
  # GET /m_customs/1.json
  def show
    if not params[:header_no_dsp].blank?
      @header_no_dsp = 1
    end
    @routecode = params[:routecode]
    @m_custom = MCustom.joins("LEFT JOIN m_customs admin ON admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code")
    @m_custom = @m_custom.joins("LEFT JOIN m_combos c ON c.class_1='#{G_ADMIN_TYPE_CLASS_1}' and c.class_2=0 and c.class_code=admin.admin_type")
    @m_custom = @m_custom.joins("LEFT JOIN m_combos c2 ON c2.class_1='#{G_USE_CONTENT_CLASS_1}' and c2.class_2=0 and c2.class_code=m_customs.use_content")
    @m_custom = @m_custom.where("m_customs.id=?",params[:id]).select("m_customs.*, admin.cust_name as admin_name, admin.tel_no as admin_tel, admin.email as admin_email, c.class_name as type_name, c2.class_name as use_content_name, -1 as window_id").first
    
    @m_route_points = MRoutePoint.joins("INNER JOIN m_routes r ON r.route_code=m_route_points.route_code")
    # 委託会社が設定されている場合
    strwhere = ""
    if not current_user.itaku_code.blank?
      strwhere = " and m_route_rundates.itaku_code = '#{current_user.itaku_code}'"
      strwhere_itaku = " and mrr2.itaku_code = '#{current_user.itaku_code}'"
      @m_route_points = @m_route_points.joins("INNER JOIN (select route_code from m_route_rundates where itaku_code='#{current_user.itaku_code}' group by route_code) mrr on mrr.route_code=m_route_points.route_code")
    end
    @m_route_points = @m_route_points.joins("left join (select mrr2.route_code, mrr2.itaku_code, max(itaku.cust_name) as itaku_name from m_route_rundates mrr2 left join m_customs itaku on itaku.cust_kbn='#{G_CUST_KBN_GYOSHA}' and itaku.cust_code=mrr2.itaku_code where itaku_code is not null and itaku_code<>'' #{strwhere_itaku} group by route_code, itaku_code) mrr2 on mrr2.route_code=m_route_points.route_code")
    @m_route_points = @m_route_points.where("r.delete_flg=0 and m_route_points.cust_kbn=? and m_route_points.cust_code=?",@m_custom.cust_kbn, @m_custom.cust_code)
    @m_route_points = @m_route_points.select("m_route_points.route_code, r.route_name, '' as route_memo, group_concat(DISTINCT concat(mrr2.itaku_name) ORDER BY mrr2.route_code, mrr2.itaku_code SEPARATOR ' 、') as itaku_name")
    @m_route_points = @m_route_points.group("m_route_points.route_code").order("m_route_points.route_code")
    iCount = 0
    @m_route_points.each do |m_route_point|
      @m_route_rundates = MRouteRundate.joins("left join m_combos week on week.class_1='#{G_WEEK_CLASS_1}' and week.class_2=0 and week.class_code=m_route_rundates.run_week")
      @m_route_rundates = @m_route_rundates.joins("left join m_combos yobi on yobi.class_1='#{G_YOBI_CLASS_1}' and yobi.class_2=0 and yobi.class_code=m_route_rundates.run_yobi")
      @m_route_rundates = @m_route_rundates.joins("left join m_combos item on item.class_1='#{G_ITEM_CLASS_1}' and item.class_2=0 and item.class_code=m_route_rundates.item_kbn")
      @m_route_rundates = @m_route_rundates.select("max(item.class_name) as item_name, group_concat(DISTINCT concat(week.class_name,yobi.class_name) ORDER BY m_route_rundates.item_kbn, m_route_rundates.tree_no SEPARATOR ' 、') as route_memo")
      @m_route_rundates = @m_route_rundates.where("route_code=?"+strwhere.to_s, m_route_point.route_code).group("m_route_rundates.item_kbn").order("m_route_rundates.item_kbn, m_route_rundates.tree_no, m_route_rundates.id")
      @route_memo = ""
      @m_route_rundates.each do |m_route_rundate|
        @route_memo = @route_memo + m_route_rundate.item_name.to_s + "　" + m_route_rundate.route_memo.to_s + "<br>"
      end
      @m_route_points[iCount].route_memo = @route_memo
      iCount = iCount + 1
    end
    
    @itaku = @m_route_points.first
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @m_custom }
    end
  end

  # GET /m_customs/new
  def new
    @m_custom = MCustom.new
    @m_custom.m_custom_rundates.build           # ← 追加: ネスト1行だけ初期表示
    load_combo_options                          # ← 追加: セレクト用データ

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @m_custom }
    end
  end

  # GET /m_customs/1/edit
  def edit
    if not params[:header_no_dsp].blank?
      @header_no_dsp = 1
    end

    @routecode = params[:routecode]
    @m_custom = MCustom.joins("LEFT JOIN m_customs admin ON admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code").joins("LEFT JOIN m_combos c ON c.class_1='#{G_ADMIN_TYPE_CLASS_1}' and c.class_2=0 and c.class_code=admin.admin_type").where("m_customs.id=?", params[:id]).select("m_customs.*,admin.cust_name as admin_name, c.class_name as type_name, -1 as window_id").first
    @m_route_points = MRoutePoint.joins("INNER JOIN m_routes r ON r.route_code=m_route_points.route_code")
    @m_route_points = @m_route_points.joins("left join (select route_code from m_route_rundates where itaku_code='#{current_user.itaku_code}' group by route_code) mrr on mrr.route_code=m_route_points.route_code")
    @m_route_points = @m_route_points.where("r.delete_flg=0 and m_route_points.cust_kbn=? and m_route_points.cust_code=?", @m_custom.cust_kbn, @m_custom.cust_code)
    @m_route_points = @m_route_points.select("m_route_points.route_code, m_route_points.tree_no, mrr.route_code as itaku_check").order("m_route_points.route_code")
    
    @m_routes = MRoute
    if not current_user.itaku_code.blank?
      @m_routes = @m_routes.joins("inner join (select route_code from m_route_rundates where itaku_code='#{current_user.itaku_code}' group by route_code) mrr on mrr.route_code=m_routes.route_code")
    end
    @m_routes = @m_routes.where("delete_flg = 0").order("route_code, id").map{|i| [i.route_code + ':' + i.route_name, i.route_code] }
    @use_contents = MCombo.where("class_1='#{G_USE_CONTENT_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
  end

  # POST /m_customs
  # POST /m_customs.json
  def create
    
    if params[:chg_flg]
      if params[:chg_flg][0]=="1"
        # 管理者情報取得
        @admin = MCustom.joins("LEFT JOIN m_combos c ON c.class_1='#{G_ADMIN_TYPE_CLASS_1}' and c.class_2=0 and c.class_code=m_customs.admin_type").where("m_customs.cust_kbn='#{G_CUST_KBN_ADMIN}' and m_customs.cust_code=?", params[:admin_code_new][0]).select("m_customs.cust_name, c.class_name").first
        if not @admin.nil?
          @cust_name = @admin.cust_name
          @admin_type = @admin.class_name
        else
          @cust_name = ""
          @admin_type = ""
        end
        @ajaxflg = 5
      end
      if params[:chg_flg][0]=="2"
        # 管理者存在チェック
        if params[:admin_code_chk][0] == ""
          @ajaxflg = 1
        else
          @admin = MCustom.joins("LEFT JOIN m_combos c ON c.class_1='#{G_ADMIN_TYPE_CLASS_1}' and c.class_2=0 and c.class_code=m_customs.admin_type").where("m_customs.cust_kbn='#{G_CUST_KBN_ADMIN}' and m_customs.cust_code=?", params[:admin_code_chk][0]).select("m_customs.cust_name, c.class_name").first
          if not @admin.nil?
            @ajaxflg = 1
          else
            @ajaxflg = -5
          end
        end
      end
    end
  end

  # PATCH/PUT /m_customs/1
  # PATCH/PUT /m_customs/1.json
  def update
    @m_custom = MCustom.find(params.expect(:id))
    
    if params[:routecode].blank?
      MRoutePoint.joins("INNER JOIN m_routes r ON r.route_code=m_route_points.route_code").where("r.delete_flg=0 and m_route_points.cust_kbn=? and m_route_points.cust_code=?", @m_custom.cust_kbn, @m_custom.cust_code).destroy_all
      params[:cnt_no].to_i.times do |i|
        if not params[:route_code].nil?
          if not params[:route_code][i].nil?
            #存在チェック
            @m_route_point_find = MRoutePoint.where("route_code=? and cust_kbn=? and cust_code=?", params[:route_code][i], @m_custom.cust_kbn, @m_custom.cust_code).first
            if @m_route_point_find.nil?
              if params[:route_code][i]==params[:route_code_old][i]
                @m_route_point = MRoutePoint.new(:route_code => params[:route_code][i], :tree_no=> params[:tree_no_old][i], :cust_kbn => @m_custom.cust_kbn, :cust_code => @m_custom.cust_code)
              else
                @tree_no = MRoutePoint.where("route_code=?", params[:route_code][i]).maximum(:tree_no).to_i + 1
                @m_route_point = MRoutePoint.new(:route_code => params[:route_code][i], :tree_no=> @tree_no, :cust_kbn => @m_custom.cust_kbn, :cust_code => @m_custom.cust_code)
              end
            end
            @m_route_point.save
          end
        end
      end
    end
    respond_to do |format|
      if !params[:icon].blank?
        if params[:icon][:delete].to_s=="1"
          params[:m_custom][:icon] = nil
        end
      end
      if @m_custom.update(m_customs_params)
        change_comment = @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
        api_log_hists(301, 2, change_comment)
        logger.fatal(current_user.user_id.to_s + "_m_customs_upd")
        if params[:lat_del]
          if params[:routecode].blank?
            @url_para = request.fullpath + "?zoom_del=" + params[:zoom_del] + "&lat_del=" + params[:lat_del] + "&lng_del=" + params[:lng_del]
          else
            @url_para = request.fullpath.split("m_customs")[0] + "m_route_points?zoom_del=" + params[:zoom_del] + "&lat_del=" + params[:lat_del] + "&lng_del=" + params[:lng_del] + "&routecode=" + params[:routecode]
          end
          format.html { redirect_to @url_para, notice: '更新処理が完了しました' }
        elsif not params[:header_no_dsp].blank?
          @url_para = request.fullpath + "?header_no_dsp=" + params[:header_no_dsp]
          format.html { redirect_to @url_para, notice: '更新処理が完了しました' }
        else
          format.html { redirect_to m_custom_url.to_s+@search_params.to_s, notice: '更新作業が完了しました。' }
        end
      else
        format.html { render action: 'edit' }
        format.json { render json: @m_custom.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /m_customs/1
  # DELETE /m_customs/1.json
  def destroy
    @m_custom = MCustom.find(params[:id])
    if @m_custom.delete_flg==1
      @m_custom.update(:delete_flg => 0)
      message_txt = "復活作業が完了しました。"
      change_type = 8
    else
      @m_custom.update(:delete_flg => 1)
      message_txt = "削除作業が完了しました。"
      change_type = 3
    end
    respond_to do |format|
      change_comment = @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
      api_log_hists(301, change_type, change_comment)
      logger.fatal(current_user.user_id.to_s + "_m_customs_dlt")
      if params[:lat_del]
        @url_para = request.fullpath.split("m_customs")[0] + "m_custom_add?zoom_del=" + params[:zoom_del] + "&lat_del=" + params[:lat_del] + "&lng_del=" + params[:lng_del]
        format.html { redirect_to @url_para }
      else
        format.html { redirect_to m_customs_url.to_s+@search_params.to_s, notice: message_txt }
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

    def set_hold_params
      @search_page = params[:search_page]
      @search_custcode = params[:search_custcode]
      @search_custname = params[:search_custname]
      @search_custaddr = params[:search_custaddr]
      @search_custadmin = params[:search_custadmin]
      @search_routecode = params[:search_routecode]
      @search_custpage = params[:search_custpage]
      @search_delete = params[:search_delete]
    end

    def set_search_params
      @search_param = ""

      if not params[:hold_params].blank?
        @search_params = @search_params.to_s + "hold_params=" + params[:hold_params]
        @search_params = @search_params.to_s + "&search_custcode=" + ERB::Util.url_encode(params[:search_custcode])
        @search_params = @search_params.to_s + "&search_custname=" + ERB::Util.url_encode(params[:search_custname])
        @search_params = @search_params.to_s + "&search_custaddr=" + ERB::Util.url_encode(params[:search_custaddr])
        @search_params = @search_params.to_s + "&search_custadmin=" + ERB::Util.url_encode(params[:search_custadmin])
        @search_params = @search_params.to_s + "&search_routecode=" + ERB::Util.url_encode(params[:search_routecode])
        @search_params = @search_params.to_s + "&search_custpage=" + ERB::Util.url_encode(params[:search_custpage])
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

    def m_customs_params
      params.require(:m_custom).permit!
      #params.expect(m_custom: [....])
    end

    # ▼ 追加: セレクト用オプションを m_combos からロード
    def load_combo_options
      @week_opts = MCombo.weeks.map { |c| [c.label, c.class_code] }
      @yobi_opts = MCombo.yobis.map { |c| [c.label, c.class_code] }
      @item_opts = MCombo.items.map { |c| [c.label, c.class_code] }
      @unit_opts = MCombo.units.map { |c| [c.label, c.class_code] }
    end

    # ▼ 追加: フォームで最低1行は表示
    def build_minimum_rundate_rows
      @m_custom.m_custom_rundates.build if @m_custom.m_custom_rundates.empty?
    end
end
