class AdminsController < ApplicationController

  before_action :authenticate_user!

  # GET /admin
  def index
    @search_mode = params[:search_mode]
    if @search_mode.to_s == "1"
      @header_no_dsp = 1  #メニューバーを表示しない
    end
    
    custcode = params[:search].nil? ? "" : params[:search][:query]
    custcode = params[:search_cust_code].blank? ? custcode : params[:search_cust_code]
    custname = params[:search_name].nil? ? "" : params[:search_name][:query]
    custemail = params[:search_email].nil? ? "" : params[:search_email][:query]
    custtel = params[:search_tel].nil? ? "" : params[:search_tel][:query]
    custtype = params[:search_type].nil? ? "" : params[:search_type][:query]
    district_code = params[:search_district].nil? ? "" : params[:search_district][:query]
    deleteflg = params[:search_delete].nil? ? "m_customs.delete_flg=0" : "m_customs.delete_flg=" + params[:search_delete][:query]
    @blndelete = params[:search_delete].nil? ? false : params[:search_delete][:query]=="1" ? true : false
    @bgcolor_td = params[:search_delete].nil? ? "" : params[:search_delete][:query]=="1" ? "bgcolor=lightgrey" : ""
    strwhere = deleteflg
    strwhere = strwhere + " and cust_kbn='#{G_CUST_KBN_ADMIN}'"
    # 管理者ｺｰﾄﾞ
    if custcode != ""
      strwhere = strwhere + " and m_customs.cust_code='#{custcode}'"
    end
    # 管理者名
    if custname != ""
      strwhere = strwhere + " and m_customs.cust_name like '%#{custname}%'"
    end
    # Ｅメール
    if custemail != ""
      strwhere = strwhere + " and m_customs.email like '%#{custemail}%'"
    end
    # 電話番号
    if custtel != ""
      strwhere = strwhere + " and m_customs.tel_no like '%#{custtel}%'"
    end
    # 種別
    if custtype != ""
      strwhere = strwhere + " and m_customs.admin_type='#{custtype}'"
    end
    # 地区
    if district_code != ""
      strwhere = strwhere + " and m_customs.district_code='#{district_code}'"
    end
    @m_customs = MCustom.joins("LEFT JOIN m_combos ON m_combos.class_1='#{G_ADMIN_TYPE_CLASS_1}' and m_combos.class_2=0 and m_combos.class_code=m_customs.admin_type").joins("LEFT JOIN m_combos d ON d.class_1='#{G_DISTRICT_CLASS_1}' AND d.class_2=0 AND d.class_code=m_customs.district_code").page(params[:page]).per("#{G_DEF_PAGE_PER}").where("#{strwhere}").select("m_customs.*, m_combos.class_name, d.class_name as district").order("m_customs.admin_type, m_customs.seq, m_customs.cust_code")
    @admin_types = MCombo.where("class_1='#{G_ADMIN_TYPE_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code")
    @districts = MCombo.where("class_1=? and class_2=0 and delete_flg=0",G_DISTRICT_CLASS_1).order("class_code asc").map{|i| [i.class_name, i.class_code] }

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /admin/1
  def show
    @m_custom = MCustom.where("m_customs.id=?", params[:id]).joins("LEFT JOIN m_combos ON m_combos.class_1='#{G_ADMIN_TYPE_CLASS_1}' and m_combos.class_2=0 and m_combos.class_code=m_customs.admin_type LEFT JOIN m_combos d ON d.class_1='#{G_DISTRICT_CLASS_1}' AND d.class_2=0 AND d.class_code=m_customs.district_code").select("m_customs.*, m_combos.class_name, d.class_name as district").first
    @station_details = MCustom.where("cust_kbn='#{G_CUST_KBN_STATION}' and admin_code=?", @m_custom.cust_code).select("m_customs.*, case when delete_flg=1 then 'bgcolor=lightgrey' else '' end as bg_color").order("cust_code")
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /admin/new
  def new
    @search_mode = params[:search_mode]
    if @search_mode.to_s == "1"
      @header_no_dsp = 1  #メニューバーを表示しない
    end
    @m_custom = MCustom.new
    @admin_types = MCombo.where("class_1=? and class_2=0 and delete_flg=0",G_ADMIN_TYPE_CLASS_1).order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @districts = MCombo.where("class_1=? and class_2=0 and delete_flg=0",G_DISTRICT_CLASS_1).order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @numberings = MCombo.where("class_1=? and class_2=? and delete_flg=0", G_NUMBERING_1, G_CUST_KBN_ADMIN).order("class_code asc")
    @action_form = 'create'
    @class_form = 'new_admin'
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /admin/1/edit
  def edit
    @search_mode = params[:search_mode]
    if @search_mode.to_s == "1"
      @header_no_dsp = 1  #メニューバーを表示しない
    end
    @m_custom = MCustom.find(params[:id])
    @admin_types = MCombo.where("class_1=? and class_2=0 and delete_flg=0",G_ADMIN_TYPE_CLASS_1).order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @districts = MCombo.where("class_1=? and class_2=0 and delete_flg=0",G_DISTRICT_CLASS_1).order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @action_form = 'update'
    @class_form = 'edit_admin'
  end

  # POST /admin
  def create
    @search_mode = params[:search_mode]
    if @search_mode.to_s == "1"
      @header_no_dsp = 1  #メニューバーを表示しない
    end
    # 自動採番処理
    @numberings = MCombo.where("class_1=? and class_2=? and delete_flg=0", G_NUMBERING_1, G_CUST_KBN_ADMIN).order("class_code asc")
    if params[:hokan][:numbering_flg].to_s=="0"
      #除外管理者種別取得
      strwhere = "cust_kbn='#{G_CUST_KBN_ADMIN}'"
      @numberings.each do |numbering|
        strwhere = strwhere + " and (cust_code< '#{numbering.value.to_s}' or cust_code>'#{numbering.value2.to_s}')"
      end
      custcode = MCustom.where("#{strwhere}").maximum(:cust_code).to_i + 1
      @custcode = "%05d" % custcode
      params[:m_custom][:cust_code]=@custcode
    end
    
    @m_custom = MCustom.new(m_custom_params)
    @admin_types = MCombo.where("class_1=? and class_2=0 and delete_flg=0",G_ADMIN_TYPE_CLASS_1).order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @districts = MCombo.where("class_1=? and class_2=0 and delete_flg=0",G_DISTRICT_CLASS_1).order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @action_form = 'create'
    
    respond_to do |format|
      if @m_custom.save
        change_comment = @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
        api_log_hists(401, 1, change_comment)
        logger.fatal(current_user.user_id.to_s + "_m_admins_add")
        #format.html { redirect_to @m_custom, notice: '追加処理が完了しました' }
        if @search_mode.to_s == "1"
          format.html { redirect_to :action => "index", :search_mode => @search_mode, :search_cust_code => @m_custom.cust_code, notice: '追加処理が完了しました' }
        else
          format.html { redirect_to :action => "show", :id => @m_custom.id, notice: '追加処理が完了しました' }
        end
      else
        format.html { render action: 'new' }
      end
    end
  end

  # PATCH/PUT /admin/1
  def update
    @search_mode = params[:search_mode]
    if @search_mode.to_s == "1"
      @header_no_dsp = 1  #メニューバーを表示しない
    end
    @m_custom = MCustom.find(params[:id])
    @admin_types = MCombo.where("class_1=? and class_2=0 and delete_flg=0",G_ADMIN_TYPE_CLASS_1).order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @districts = MCombo.where("class_1=? and class_2=0 and delete_flg=0",G_DISTRICT_CLASS_1).order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @action_form = 'update'

    respond_to do |format|
      if @m_custom.update(m_custom_params)
        change_comment = @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
        api_log_hists(401, 2, change_comment)
        logger.fatal(current_user.user_id.to_s + "_m_admins_upd")
        #format.html { redirect_to @m_custom, notice: '更新処理が完了しました' }
        format.html { redirect_to :action => "show", :id => @m_custom.id, notice: '更新処理が完了しました' }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  # DELETE /admin/1
  def destroy
    @m_custom = MCustom.find(params[:id])
    if @m_custom.delete_flg==1
      @m_custom.update(:delete_flg => 0)
      change_type = 8
    else
      @m_custom.update(:delete_flg => 1)
      change_type = 3
    end
    respond_to do |format|
      change_comment = @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
      api_log_hists(401, change_type, change_comment)
      logger.fatal(current_user.user_id.to_s + "_m_admins_dlt")
      format.html { redirect_to admins_url }
    end
  end

  private

  def m_custom_params
    params.require(:m_custom).permit!
  end
end
