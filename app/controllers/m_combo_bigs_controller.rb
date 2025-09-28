class MComboBigsController < ApplicationController

  before_action :authenticate_user!

  # GET /m_combo_bigs
  # GET /m_combo_bigs.json
  def index
    classname = params[:search].nil? ? "" : params[:search][:query]
    deleteflg = params[:search].nil? ? "m_combo_bigs.delete_flg=0" : "m_combo_bigs.delete_flg=" + params[:search][:delete]
    if current_user.authority != 1
      jogaicode = " AND m_combo_bigs.class_1<>0"
    else
      jogaicode = ""
    end
    @blndelete = params[:search].nil? ? false : params[:search][:delete]=="1" ? true : false
    @bgcolor_td = params[:search].nil? ? "" : params[:search][:delete]=="1" ? "bgcolor=lightgrey" : ""
    
    if classname == ""
      strwhere = deleteflg + jogaicode
    else
      strwhere = deleteflg + jogaicode + " AND class_name like '%#{classname}%'"
    end
    @m_combo_bigs = MComboBig.page(params[:page]).per("#{G_DEF_PAGE_PER}").where("#{strwhere}").order("m_combo_bigs.class_1")
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @m_combo_bigs }
    end
  end

  # GET /m_combo_bigs/1
  # GET /m_combo_bigs/1.json
  def show
    @m_combo_big = MComboBig.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @m_combo_big }
    end
  end

  # GET /m_combo_bigs/new
  def new
    @m_combo_big = MComboBig.new
    @action_form = 'create'

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @m_combo_big }
    end
  end

  # GET /m_combo_bigs/1/edit
  def edit
    @m_combo_big = MComboBig.find(params[:id])
    @action_form = 'update'
  end

  # POST /m_combo_bigs
  # POST /m_combo_bigs.json
  def create
    
    @m_combo_big = MComboBig.new(params[:m_combo_big])

    respond_to do |format|
      if @m_combo_big.save
        change_comment = @m_combo_big.class_1.to_s + ":" + @m_combo_big.class_name.to_s
        api_log_hists(701, 1, change_comment)
        logger.fatal(current_user.user_id.to_s + "_m_combo_bigs_add")
        format.html { redirect_to @m_combo_big, notice: '追加処理が完了しました' }
        format.json { render action: 'show', status: :created, location: @m_combo_big }
      else
        format.html { render action: 'new' }
        format.json { render json: @m_combo_big.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /m_combo_bigs/1
  # PATCH/PUT /m_combo_bigs/1.json
  def update
    @m_combo_big = MComboBig.find(params[:id])
    
    respond_to do |format|
      if @m_combo_big.update(m_combo_big_params)
        change_comment = @m_combo_big.class_1.to_s + ":" + @m_combo_big.class_name.to_s
        api_log_hists(701, 2, change_comment)
        logger.fatal(current_user.user_id.to_s + "_m_combo_bigs_upd")
        format.html { redirect_to @m_combo_big, notice: '更新処理が完了しました' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @m_combo_big.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /m_combo_bigs/1
  # DELETE /m_combo_bigs/1.json
  def destroy
    @m_combo_big = MComboBig.find(params[:id])
    if @m_combo_big.delete_flg==1
      @m_combo_big.update(:delete_flg => 0)
      change_type = 8
    else
      @m_combo_big.update(:delete_flg => 1)
      change_type = 3
    end
    respond_to do |format|
      change_comment = @m_combo_big.class_1.to_s + ":" + @m_combo_big.class_name.to_s
      api_log_hists(701, change_type, change_comment)
      logger.fatal(current_user.user_id.to_s + "_m_combo_bigs_dlt")
      format.html { redirect_to m_combo_bigs_url }
      format.json { head :no_content }
    end
  end

  private

  def m_combo_big_params
    params.expect(m_combo_big: [ :class_1, :class_name, :class_namea, :system_name, :system_flg, :delete_flg ])
  end
end
