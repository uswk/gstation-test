class TChangeShinseiAdminsController < ApplicationController

  before_action :authenticate_user!

  # GET /t_change_shinsei_admins
  def index
    custcode = params[:search].nil? ? "" : params[:search][:query]
    custname = params[:search_name].nil? ? "" : params[:search_name][:query]
    confirm_flg = params[:search_confirm].nil? ? 0 : params[:search_confirm][:query]
    strdate = params[:search_str].nil? ? "" : params[:search_str][:str_date]
    enddate = params[:search_end].nil? ? "" : params[:search_end][:end_date]
    @bln_all = params[:search_all].nil? ? false : params[:search_all][:query]=="1" ? true : false
    strwhere = " t_change_shinseis.cust_kbn='#{G_CUST_KBN_ADMIN}'"
    # 管理者ｺｰﾄﾞ
    if custcode != ""
      strwhere = strwhere + " AND t_change_shinseis.cust_code like '%#{custcode}%'"
    end
    # 管理者名
    if custname != ""
      strwhere = strwhere + " AND mc.cust_name like '%#{custname}%'"
    end
    # ステータス
    if confirm_flg != ""
      strwhere = strwhere + " AND t_change_shinseis.confirm_flg = '#{confirm_flg}'"
    end
    # 希望日開始
    if strdate != ""
      strwhere = strwhere + " AND t_change_shinseis.kibou_date>='#{strdate}'"
    end
    # 希望日終了
    if enddate != ""
      enddate2 = enddate.to_date+1
      strwhere = strwhere + " AND t_change_shinseis.kibou_date<'#{enddate2}'"
    end
    
    @t_change_shinseis = TChangeShinsei.joins("left join m_combos c2 on c2.class_1='#{G_CONFIRM_CLASS_1}' and c2.class_2=0 and c2.class_code=t_change_shinseis.confirm_flg").where("#{strwhere}").select("t_change_shinseis.*, c2.class_name as confirm_name").order("t_change_shinseis.shinsei_date, id")
    if @bln_all==false
      @t_change_shinseis = @t_change_shinseis.page(params[:page]).per("#{G_DEF_PAGE_PER}")
    end
    @confirm_flgs = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_CONFIRM_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /t_change_shinsei_admins/1
  def show
    id_array = params[:id].split("_")
    @action_flg = params[:action_flg]
    @t_change_shinsei = TChangeShinsei.find(id_array[0], :joins => "left join m_combos c2 on c2.class_1='#{G_CONFIRM_CLASS_1}' and c2.class_2=0 and c2.class_code=t_change_shinseis.confirm_flg left join m_combos c3 on c3.class_1='#{G_ADMIN_TYPE_CLASS_1}' and c3.class_2=0 and c3.class_code=t_change_shinseis.admin_type LEFT JOIN m_combos c4 on c4.class_1='#{G_DISTRICT_CLASS_1}' and c4.class_2=0 and c4.class_code=t_change_shinseis.district_code", :select => "t_change_shinseis.*, c2.class_name as confirm_name, c3.class_name as admin_type_name, c4.class_name as district")
    @m_custom = MCustom.joins("left join m_combos c on c.class_1='#{G_ADMIN_TYPE_CLASS_1}' and c.class_2=0 and c.class_code=m_customs.admin_type").joins("left join m_combos d on d.class_1='#{G_DISTRICT_CLASS_1}' and d.class_2=0 and d.class_code=m_customs.district_code").where("m_customs.cust_kbn=? and m_customs.cust_code=?", @t_change_shinsei.cust_kbn, @t_change_shinsei.cust_code).select("m_customs.*, c.class_name as admin_type_name, d.class_name as district").first
    
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /t_change_shinsei_admins/new
  def new
    @t_change_shinsei = TChangeShinsei.new
    @m_custom = MCustom.where("m_customs.id=?", params[:id]).select("m_customs.*, -1 as window_id").first
    @m_route_point = MRoutePoint.joins("left join m_routes mr on mr.route_code=m_route_points.route_code").where("m_route_points.cust_kbn=? and m_route_points.cust_code=? and mr.delete_flg=0", @m_custom.cust_kbn, @m_custom.cust_code).select("m_route_points.route_code").first
    @shinsei_kbns = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_SHINSEI_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @confirm_flgs = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_CONFIRM_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @route_codes = MRoute.where("delete_flg=0").order("m_routes.route_code asc").map{|i| [i.route_name, i.route_code] }

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /t_change_shinsei_admins/1/edit
  def edit
    @t_change_shinsei = TChangeShinsei.find(params[:id])
    @admin_types = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_ADMIN_TYPE_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @districts = MCombo.where("class_1=? and class_2=0 and delete_flg=0",G_DISTRICT_CLASS_1).order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @confirm_flgs = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_CONFIRM_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
  end

  # POST /t_change_shinsei_admins
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
          change_comment = @t_change_shinsei.cust_code.to_s + ":" + @t_change_shinsei.cust_name.to_s
          api_log_hists(1201, 1, change_comment)
          logger.fatal(current_user.user_id.to_s + "_t_change_shinsei_admins_add")
          @url_para = request.fullpath + "/" + @t_change_shinsei.id.to_s + "?action_flg=1"
          format.html { redirect_to @url_para, notice: '追加処理が完了しました' }
        else
          format.html { render action: 'new' }
        end
      end
    end
  end

  # PATCH/PUT /t_change_shinsei_admins/1
  def update
    @admin_types = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_ADMIN_TYPE_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @districts = MCombo.where("class_1=? and class_2=0 and delete_flg=0",G_DISTRICT_CLASS_1).order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @confirm_flgs = MCombo.where("class_1=? and class_2=0 and delete_flg = 0", G_CONFIRM_CLASS_1).order("class_2 asc, class_code asc").map{|i| [i.class_name, i.class_code] }
    @t_change_shinsei = TChangeShinsei.find(params[:id])

    respond_to do |format|
      if @t_change_shinsei.update(params[:t_change_shinsei])
        change_comment = @t_change_shinsei.cust_code.to_s + ":" + @t_change_shinsei.cust_name.to_s
        api_log_hists(1201, 2, change_comment)
        logger.fatal(current_user.user_id.to_s + "_t_change_shinsei_admins_upd")
        format.html { redirect_to :action => "show", :id => @t_change_shinsei.id, :notice => '更新処理が完了しました' }
      else
        format.html { render action: 'edit' }
      end
    end
  end
end
