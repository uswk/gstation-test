class UnloadsController < ApplicationController

  before_action :authenticate_user!
  before_action :set_map_key
  before_action :set_zenrin_map_key
  before_action :set_hold_params, only: [:show, :edit, :new, :create, :update]
  before_action :set_search_params, only: [:index, :create, :update, :destroy]

  # GET /unloads
  def index
    @def_lat = A_DEF_LATITUDE;
    @def_lng = A_DEF_LONGITUDE;
    
    if params[:hold_params].blank?
      @custcode = params[:search].blank? ? "" : params[:search][:cust_code]
      @custname = params[:search].blank? ? "" : params[:search][:cust_name]
      @custaddr = params[:search].blank? ? "" : params[:search][:cust_addr]
      @custpage = params[:search].blank? ? G_CUSTOM_PAGE_PER : params[:search][:cust_page]
      @deleteflg = params[:search].blank? ? 0 : params[:search][:delete]
      @blndelete = params[:search].blank? ? false : params[:search][:delete]=="1" ? true : false
    else
      @custcode = params[:search_custcode].blank? ? "" : params[:search_custcode]
      @custname = params[:search_custname].blank? ? "" : params[:search_custname]
      @custaddr = params[:search_custaddr].blank? ? "" : params[:search_custaddr]
      @custpage = params[:search_custpage].blank? ? G_CUSTOM_PAGE_PER : params[:search_custpage]
      @deleteflg = params[:search_delete].blank? ? 0 : params[:search_delete]
      @blndelete = params[:search_delete].blank? ? false : params[:search_delete]=="1" ? true : false
    end
    @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
    strwhere = "m_customs.delete_flg='#{@deleteflg}'"
    strwhere = strwhere + " and m_customs.cust_kbn='#{G_CUST_KBN_UNLOAD}'"
    # 荷下先ｺｰﾄﾞ
    if @custcode != ""
      strwhere = strwhere + " and m_customs.cust_code='#{@custcode}'"
    end
    # 荷下先名
    if @custname != ""
      strwhere = strwhere + " and m_customs.cust_name like '%#{@custname}%'"
    end
    # 住所
    if @custaddr != ""
      strwhere = strwhere + " and m_customs.addr_1 like '%#{@custaddr}%'"
    end
    
    if current_user.authority==9
      custom_select = ",-5 as window_id"
    else
      custom_select = ",0 as window_id"
    end
    @m_customs = MCustom
    @m_customs = @m_customs.where("#{strwhere}").select("m_customs.*, case when (m_customs.start_date is null OR m_customs.start_date<='#{@now_date}') AND (m_customs.end_date is null OR m_customs.end_date>='#{@now_date}') AND m_customs.delete_flg=0 then '' else 'lightgrey' end as bgcolor " + custom_select.to_s)
    @m_customs = @m_customs.page(params[:page]).per("#{@custpage}").order("cust_code, id")

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /m_unloads/1
  def show
    if not params[:header_no_dsp].blank?
      @header_no_dsp = 1
    end
    @routecode = params[:routecode]
    @m_custom = MCustom.joins("LEFT JOIN m_customs admin ON admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code")
    @m_custom = @m_custom.joins("LEFT JOIN m_combos c ON c.class_1='#{G_ADMIN_TYPE_CLASS_1}' and c.class_2=0 and c.class_code=admin.admin_type")
    @m_custom = @m_custom.joins("LEFT JOIN m_combos c2 ON c2.class_1='#{G_USE_CONTENT_CLASS_1}' and c2.class_2=0 and c2.class_code=m_customs.use_content")
    @m_custom = @m_custom.where("m_customs.id=?",params[:id]).select("m_customs.*, admin.cust_name as admin_name, admin.tel_no as admin_tel, admin.email as admin_email, c.class_name as type_name, c2.class_name as use_content_name, -1 as window_id").first
    
    @m_collect_industs = MCollectIndust.joins("left join m_combos item on item.class_1='#{G_ITEM_CLASS_1}' and item.class_code=m_collect_industs.indust_kbn")
    @m_collect_industs = @m_collect_industs.joins("left join m_combos unit on unit.class_1='#{G_UNIT_CLASS_1}' and unit.class_code=m_collect_industs.unit_kbn")
    @m_collect_industs = @m_collect_industs.where("m_collect_industs.cust_kbn=? and m_collect_industs.cust_code=?", @m_custom.cust_kbn, @m_custom.cust_code)
    @m_collect_industs = @m_collect_industs.select("m_collect_industs.*, item.class_name as indust_name, unit.class_name as unit_name").order("m_collect_industs.tree_no, m_collect_industs.indust_kbn, m_collect_industs.id")
    
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /unloads/new
  def new
  end

  # GET /unloads/1/edit
  def edit
    if not params[:header_no_dsp].blank?
      @header_no_dsp = 1
    end
    @m_custom = MCustom.where("m_customs.id=?", params[:id]).select("m_customs.*, -1 as window_id").first
    @m_collect_industs = MCollectIndust.where("cust_kbn=? and cust_code=?", @m_custom.cust_kbn, @m_custom.cust_code).order("tree_no, indust_kbn, id")
    
    @indust_kbns = MCombo.where("class_1='#{G_ITEM_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @unit_kbns = MCombo.where("class_1='#{G_UNIT_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
  end

  # POST /m_unloads
  def create
  end

  # PATCH/PUT /m_customs/1
  def update
    @m_custom = MCustom.find(params[:id])
    
    MCollectIndust.where("cust_kbn=? and cust_code=?", @m_custom.cust_kbn, @m_custom.cust_code).destroy_all
    @tree_no = 0
    params[:cnt_no].to_i.times do |i|
      if not params[:indust_kbn].nil?
        if not params[:indust_kbn][i].nil?
          @tree_no = @tree_no + 1
          @m_collect_indust = MCollectIndust.new(:cust_kbn => @m_custom.cust_kbn, :cust_code => @m_custom.cust_code, :indust_kbn =>params[:indust_kbn][i] , :tree_no=> @tree_no, :unit_kbn => params[:unit_kbn][i])
          @m_collect_indust.save
        end
      end
    end
    
    respond_to do |format|
      if @m_custom.update(params[:m_custom])
        change_comment = @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
        api_log_hists(1701, 2, change_comment)
        if params[:lat_del]
          @url_para = request.fullpath + "?zoom_del=" + params[:zoom_del] + "&lat_del=" + params[:lat_del] + "&lng_del=" + params[:lng_del]
          format.html { redirect_to @url_para, notice: '更新処理が完了しました' }
        elsif not params[:header_no_dsp].blank?
          @url_para = request.fullpath + "?header_no_dsp=" + params[:header_no_dsp]
          format.html { redirect_to @url_para, notice: '更新処理が完了しました' }
        else
          format.html { redirect_to unload_url.to_s+@search_params.to_s, notice: '更新作業が完了しました。' }
        end
      else
        format.html { render action: 'edit' }
      end
    end
  end

  # DELETE /unloads/1
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
      api_log_hists(1701, change_type, change_comment)
      logger.fatal(current_user.user_id.to_s + "_m_customs_dlt")
      if params[:lat_del]
        @url_para = request.fullpath.split("unloads")[0] + "unload_add?zoom_del=" + params[:zoom_del] + "&lat_del=" + params[:lat_del] + "&lng_del=" + params[:lng_del]
        format.html { redirect_to @url_para }
      else
        format.html { redirect_to unloads_url.to_s+@search_params.to_s, notice: message_txt }
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
end
