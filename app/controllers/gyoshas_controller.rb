class GyoshasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_m_custom, only: %i[ show edit update destroy ]
  
  # GET /gyosha
  def index
    if params[:search_mode]
      @header_no_dsp = 1  #メニューバーを表示しない
      @search_mode = 1
    else
      @search_mode = 0
    end
    custcode = params[:search].nil? ? "" : params[:search][:query]
    custname = params[:search_name].nil? ? "" : params[:search_name][:query]
    custaddr = params[:search_addr].nil? ? "" : params[:search_addr][:query]
    custtel = params[:search_tel].nil? ? "" : params[:search_tel][:query]
    deleteflg = params[:search_delete].nil? ? "m_customs.delete_flg=0" : "m_customs.delete_flg=" + params[:search_delete][:query]
    @blndelete = params[:search_delete].nil? ? false : params[:search_delete][:query]=="1" ? true : false
    @bgcolor_td = params[:search_delete].nil? ? "" : params[:search_delete][:query]=="1" ? "bgcolor=lightgrey" : ""
    strwhere = deleteflg
    strwhere = strwhere + " and cust_kbn='#{G_CUST_KBN_GYOSHA}'"
    # 委託会社ｺｰﾄﾞ
    if custcode != ""
      strwhere = strwhere + " and m_customs.cust_code='#{custcode}'"
    end
    # 委託会社名
    if custname != ""
      strwhere = strwhere + " and m_customs.cust_name like '%#{custname}%'"
    end
    # 住所
    if custaddr != ""
      strwhere = strwhere + " and m_customs.addr_1 like '%#{custaddr}%'"
    end
    # 電話番号
    if custtel != ""
      strwhere = strwhere + " and m_customs.tel_no like '%#{custtel}%'"
    end
    @m_customs = MCustom.page(params[:page]).per("#{G_DEF_PAGE_PER}").where("#{strwhere}")

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /gyosha/1
  def show
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /gyosha/new
  def new
    @m_custom = MCustom.new
    @action_form = 'create'
    @class_form = 'new_gyosha'
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /gyosha/1/edit
  def edit
    @action_form = 'update'
    @class_form = 'edit_gyosha'
  end

  # POST /gyosha
  def create
    @m_custom = MCustom.new(m_custom_params)

    respond_to do |format|
      if @m_custom.save
        change_comment = @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
        api_log_hists(501, 1, change_comment)
        logger.fatal(current_user.user_id.to_s + "_gyoshas_add")
        format.html { redirect_to :action => "show", :id => @m_custom.id, notice: '追加処理が完了しました' }
      else
        format.html { render action: 'new' }
      end
    end
  end

  # PATCH/PUT /gyosha/1
  def update
    respond_to do |format|
      if @m_custom.update(m_custom_params)
        change_comment = @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
        api_log_hists(501, 2, change_comment)
        logger.fatal(current_user.user_id.to_s + "_gyoshas_upd")
        format.html { redirect_to :action => "show", :id => @m_custom.id, notice: '更新処理が完了しました' }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  # DELETE /gyosha/1
  def destroy
    if @m_custom.delete_flg==1
      @m_custom.update(:delete_flg => 0)
      change_type = 8
    else
      @m_custom.update(:delete_flg => 1)
      change_type = 3
    end
    respond_to do |format|
      change_comment = @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
      api_log_hists(501, change_type, change_comment)
      logger.fatal(current_user.user_id.to_s + "_gyoshas_dlt")
      format.html { redirect_to gyoshas_path, status: :see_other, notice: '削除処理が完了しました' }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_m_custom
    @m_custom = MCustom.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def m_custom_params
    params.expect(m_custom: [ :cust_code, :cust_name, :addr_1, :addr_2, :tel_no, :fax_no, :memo, :delete_flg, :cust_kbn ])
  end
end