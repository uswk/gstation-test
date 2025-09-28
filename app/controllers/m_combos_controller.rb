class MCombosController < ApplicationController

  before_action :authenticate_user!

  # GET /m_combos
  # GET /m_combos.json
  def index
    class1 = params[:class1]
    classname = params[:search].nil? ? "" : params[:search][:query]
    deleteflg = params[:search].nil? ? "m_combos.delete_flg=0" : "m_combos.delete_flg=" + params[:search][:delete]
    @blndelete = params[:search].nil? ? false : params[:search][:delete]=="1" ? true : false
    @bgcolor_td = params[:search].nil? ? "" : params[:search][:delete]=="1" ? "bgcolor=lightgrey" : ""
    
    if classname == ""
      strwhere = deleteflg + " AND class_1='#{class1}'"
    else
      strwhere = deleteflg + " AND class_1='#{class1}' AND class_name like '%#{classname}%'"
    end
    @m_combos = MCombo.page(params[:page]).per("#{G_DEF_PAGE_PER}").where("#{strwhere}")

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @m_combos }
    end
  end

  # GET /m_combos/1
  # GET /m_combos/1.json
  def show
    @m_combo = MCombo.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @m_combo }
    end
  end

  # GET /m_combos/new
  def new
    @m_combo = MCombo.new
    @action_form = 'create'

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @m_combo }
    end
  end

  # GET /m_combos/1/edit
  def edit
    @m_combo = MCombo.find(params[:id])
    @action_form = 'update'
  end

  # POST /m_combos
  # POST /m_combos.json
  def create
    
    @m_combo = MCombo.new(m_combo_params)

    respond_to do |format|
      if @m_combo.save
        change_comment = @m_combo.class_code.to_s + ":" + @m_combo.class_name.to_s
        api_log_hists(702, 1, change_comment)
        logger.fatal(current_user.user_id.to_s + "_m_combos_add")
        format.html { redirect_to @m_combo, notice: '追加処理が完了しました' }
        format.json { render action: 'show', status: :created, location: @m_combo }
      else
        format.html { render action: 'new' }
        format.json { render json: @m_combo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /m_combos/1
  # PATCH/PUT /m_combos/1.json
  def update
    @m_combo = MCombo.find(params[:id])
    
    respond_to do |format|
      if @m_combo.update(m_combo_params)
        change_comment = @m_combo.class_code.to_s + ":" + @m_combo.class_name.to_s
        api_log_hists(702, 2, change_comment)
        logger.fatal(current_user.user_id.to_s + "_m_combos_upd")
        format.html { redirect_to @m_combo, notice: '更新処理が完了しました' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @m_combo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /m_combos/1
  # DELETE /m_combos/1.json
  def destroy
    @m_combo = MCombo.find(params[:id])
    if @m_combo.delete_flg==1
      @m_combo.update(:delete_flg => 0)
      change_type = 8
    else
      @m_combo.update(:delete_flg => 1)
      change_type = 3
    end
    respond_to do |format|
      change_comment = @m_combo.class_code.to_s + ":" + @m_combo.class_name.to_s
      api_log_hists(702, change_type, change_comment)
      logger.fatal(current_user.user_id.to_s + "_m_combos_dlt")
      format.html { redirect_to m_combos_url :class1 => @m_combo.class_1}
      format.json { head :no_content }
    end
  end

  private

  def m_combo_params
    params.expect(m_combo: [ :class_1, :class_2, :class_code, :class_name, :class_namea, :value, :value2, :value3, :value4, :value5, :system_name, :system_flg, :delete_flg ])
  end
end
