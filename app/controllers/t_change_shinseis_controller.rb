class TChangeShinseisController < ApplicationController

  before_action :authenticate_user!
  before_action :set_map_key
  before_action :set_zenrin_map_key

  # GET /t_change_shinseis
  def index
    custcode = params[:search].nil? ? "" : params[:search][:query]
    custname = params[:search_name].nil? ? "" : params[:search_name][:query]
    shinsei_kbn = params[:search_shinsei].nil? ? "" : params[:search_shinsei][:query]
    confirm_flg = params[:search_confirm].nil? ? 0 : params[:search_confirm][:query]
    strdate = params[:search_str].nil? ? "" : params[:search_str][:str_date]
    enddate = params[:search_end].nil? ? "" : params[:search_end][:end_date]
    @bln_all = params[:search_all].nil? ? false : params[:search_all][:query]=="1" ? true : false
    strwhere = " t_change_shinseis.cust_kbn='#{G_CUST_KBN_STATION}'"
    # ｽﾃｰｼｮﾝｺｰﾄﾞ
    if custcode != ""
      strwhere = strwhere + " AND t_change_shinseis.cust_code like '%#{custcode}%'"
    end
    # ステーション名
    if custname != ""
      strwhere = strwhere + " AND mc.cust_name like '%#{custname}%'"
    end
    # 申請区分
    if shinsei_kbn != ""
      strwhere = strwhere + " AND t_change_shinseis.shinsei_kbn = '#{shinsei_kbn}'"
    end
    # ステータス
    if confirm_flg != ""
      strwhere = strwhere + " AND t_change_shinseis.confirm_flg = '#{confirm_flg}'"
    end
    #希望日開始
    if strdate != ""
      strwhere = strwhere + " AND t_change_shinseis.kibou_date>='#{strdate}'"
    end
    #希望日終了
    if enddate != ""
      enddate2 = enddate.to_date+1
      strwhere = strwhere + " AND t_change_shinseis.kibou_date<'#{enddate2}'"
    end
    
    @t_change_shinseis = TChangeShinsei.joins("LEFT JOIN m_customs mc ON mc.cust_kbn=t_change_shinseis.cust_kbn and mc.cust_code=t_change_shinseis.cust_code").joins("left join m_combos c1 on c1.class_1='#{G_SHINSEI_CLASS_1}' and c1.class_2=0 and c1.class_code=t_change_shinseis.shinsei_kbn").joins("left join m_combos c2 on c2.class_1='#{G_CONFIRM_CLASS_1}' and c2.class_2=0 and c2.class_code=t_change_shinseis.confirm_flg").where("#{strwhere}").select("t_change_shinseis.*, c1.class_name as shinsei_name, c2.class_name as confirm_name").order("t_change_shinseis.shinsei_date, id")
    if @bln_all==false
      @t_change_shinseis = @t_change_shinseis.page(params[:page]).per("#{G_DEF_PAGE_PER}")
    end
    @shinsei_kbns = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_SHINSEI_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @confirm_flgs = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_CONFIRM_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /t_change_shinseis/1
  def show
    id_array = params[:id].split("_")
    @action_flg = params[:action_flg]
    @t_change_shinsei = TChangeShinsei.find(id_array[0], :joins => "LEFT JOIN m_customs mc ON mc.cust_kbn=t_change_shinseis.cust_kbn and mc.cust_code=t_change_shinseis.cust_code left join m_combos c1 on c1.class_1='#{G_SHINSEI_CLASS_1}' and c1.class_2=0 and c1.class_code=t_change_shinseis.shinsei_kbn left join m_combos c2 on c2.class_1='#{G_CONFIRM_CLASS_1}' and c2.class_2=0 and c2.class_code=t_change_shinseis.confirm_flg left join m_customs admin on admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=t_change_shinseis.admin_code left join m_combos c3 on c3.class_1='#{G_ADMIN_TYPE_CLASS_1}' and c3.class_2=0 and c3.class_code=admin.admin_type left join m_routes mr on mr.route_code=t_change_shinseis.route_code left join m_customs itaku on itaku.cust_kbn='#{G_CUST_KBN_GYOSHA}' and itaku.cust_code=mr.itaku_code left join m_combos c4 on c4.class_1='#{G_USE_CONTENT_CLASS_1}' and c4.class_2=0 and c4.class_code=t_change_shinseis.use_content", :select => "t_change_shinseis.*, mc.latitude as latitude_bef, mc.longitude as longitude_bef, c1.class_name as shinsei_name, c2.class_name as confirm_name, admin.cust_name as admin_name, c3.class_name as admin_type_name, c4.class_name as use_content_name, mr.route_name, itaku.cust_name as itaku_name, itaku.fax_no as itaku_fax")
    @m_custom = MCustom.joins("left join m_customs admin on admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code").joins("left join m_combos c3 on c3.class_1='#{G_ADMIN_TYPE_CLASS_1}' and c3.class_2=0 and c3.class_code=admin.admin_type").joins("left join m_combos c4 on c4.class_1='#{G_USE_CONTENT_CLASS_1}' and c4.class_2=0 and c4.class_code=m_customs.use_content").where("m_customs.cust_kbn=? and m_customs.cust_code=?", @t_change_shinsei.cust_kbn, @t_change_shinsei.cust_code).joins("left join (select cust_kbn, cust_code, max(route_code) as route_code from m_route_points group by cust_kbn, cust_code) mrp on mrp.cust_kbn=m_customs.cust_kbn and mrp.cust_code=m_customs.cust_code").joins("left join m_routes mr on mr.route_code=mrp.route_code").joins("left join m_customs itaku on itaku.cust_kbn='#{G_CUST_KBN_GYOSHA}' and itaku.cust_code=mr.itaku_code").select("m_customs.*, admin.cust_name as admin_name, c3.class_name as admin_type_name, c4.class_name as use_content_name, mr.route_name, itaku.cust_name as itaku_name").first

    if id_array[1].to_s=="1"
      @atesaki = MCombo.where("class_1=0 and class_2=1 and class_code=3").first
      @hasshin = MCombo.where("class_1=0 and class_2=0 and class_code=3").first
      respond_to do |format|
        format.html { redirect_to t_change_shinsei_path(format: :pdf)}
        format.pdf do
          render pdf: 'show',
               encoding: 'UTF-8',
               layout: 'pdf.html.erb',
               show_as_html: params[:debug].present?
               change_comment = @t_change_shinsei.cust_code.to_s + ":" + @t_change_shinsei.cust_name.to_s
               api_log_hists(302, 5, change_comment)
        end
      end
    else
      respond_to do |format|
        format.html # show.html.erb
      end
    end
  end

  # GET /t_change_shinseis/new
  def new
    @t_change_shinsei = TChangeShinsei.new
    @m_custom = MCustom.where("m_customs.id=?", params[:id]).select("m_customs.*, -1 as window_id").first
    @m_route_point = MRoutePoint.joins("left join m_routes mr on mr.route_code=m_route_points.route_code").where("m_route_points.cust_kbn=? and m_route_points.cust_code=? and mr.delete_flg=0", @m_custom.cust_kbn, @m_custom.cust_code).select("m_route_points.route_code").first
    @shinsei_kbns = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_SHINSEI_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @confirm_flgs = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_CONFIRM_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @route_codes = MRoute.where("delete_flg=0").order("m_routes.route_code asc").map{|i| [i.route_name, i.route_code] }
    @use_contents = MCombo.where("class_1='#{G_USE_CONTENT_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }

    @action_form = 'create'
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /t_change_shinseis/1/edit
  def edit
    @t_change_shinsei = TChangeShinsei.find(params[:id], :joins => "LEFT JOIN m_customs mc ON mc.cust_kbn=t_change_shinseis.cust_kbn and mc.cust_code=t_change_shinseis.cust_code", :select => "t_change_shinseis.*")
    @shinsei_kbns = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_SHINSEI_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @confirm_flgs = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_CONFIRM_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @route_codes = MRoute.where("delete_flg=0").order("m_routes.route_code asc").map{|i| [i.route_name, i.route_code] }
    @use_contents = MCombo.where("class_1='#{G_USE_CONTENT_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
    
    @action_form = 'update'
  end

  # POST /t_change_shinseis
  def create
    if params[:ajax]
      @m_custom = MCustom.joins("LEFT JOIN m_combos c ON c.class_1='#{G_ADMIN_TYPE_CLASS_1}' and c.class_2=0 and c.class_code=m_customs.admin_type").where("m_customs.cust_kbn='#{G_CUST_KBN_ADMIN}' and m_customs.cust_code=?",params[:ajax][:admin_code]).select("m_customs.id, m_customs.cust_name, c.class_name").first
      if not @m_custom.nil?
        @admin_id = @m_custom.id
        @cust_name = @m_custom.cust_name
        @admin_type = @m_custom.class_name
      else
        @admin_id = ""
        @cust_name = ""
        @admin_type = ""
      end
      @cust_code = params[:ajax][:admin_code]
    else
      @t_change_shinsei = TChangeShinsei.new(params[:t_change_shinsei])
      
      respond_to do |format|
        if @t_change_shinsei.save
          @m_custom = MCustom.where("cust_kbn=? and cust_code=?", G_CUST_KBN_STATION, @t_change_shinsei.cust_code).first
          change_comment = @t_change_shinsei.cust_code.to_s + ":" + @m_custom.cust_name.to_s
          api_log_hists(302, 1, change_comment)
          logger.fatal(current_user.user_id.to_s + "_t_change_shinseis_add")
          @url_para = request.fullpath + "/" + @t_change_shinsei.id.to_s + "action_flg=1"
          format.html { redirect_to @url_para, notice: '追加処理が完了しました' }
        else
          format.html { render action: 'new' }
        end
      end
    end
  end

  # PATCH/PUT /t_change_shinseis/1
  def update
    @t_change_shinsei = TChangeShinsei.find(params[:id])

    respond_to do |format|
      if @t_change_shinsei.update(params[:t_change_shinsei])
        @m_custom = MCustom.where("cust_kbn=? and cust_code=?", G_CUST_KBN_STATION, @t_change_shinsei.cust_code).first
        change_comment = @t_change_shinsei.cust_code.to_s + ":" + @m_custom.cust_name.to_s
        api_log_hists(302, 2, change_comment)
        logger.fatal(current_user.user_id.to_s + "_t_change_shinseis_upd")
        format.html { redirect_to @t_change_shinsei, notice: '更新処理が完了しました' }
      else
        format.html { render action: 'edit' }
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
