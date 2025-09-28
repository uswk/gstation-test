class UsersController < ApplicationController

  before_action :authenticate_user!
  before_action :set_combo, :only => [:new, :edit, :add, :update]

  # GET /users
  # GET /users.json
  def index
    userid = params[:search].nil? ? "" : params[:search][:query]
    @users = User.joins("left join m_customs mc on mc.cust_kbn='#{G_CUST_KBN_GYOSHA}' and mc.cust_code=users.itaku_code").page(params[:page]).per("#{G_DEF_PAGE_PER}").where("user_id like '%#{userid}%'").select("users.*, mc.cust_name as itaku_name").order("users.user_id asc, users.id asc")

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.joins("left join m_customs mc on mc.cust_kbn='#{G_CUST_KBN_GYOSHA}' and mc.cust_code=users.itaku_code").joins("left join m_combos c on c.class_1='#{G_AUTHORITY_CLASS_1}' and c.class_code=users.authority").where("users.id=?", params[:id]).select("users.*, mc.cust_name as itaku_name, c.class_name as authority_name").first

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users/add
  def add
    #追加処理
    @user = User.new(params[:user])
    
    respond_to do |format|
      if @user.save
        change_comment = @user.user_id.to_s + ":" + @user.user_name.to_s
        api_log_hists(801, 1, change_comment)
        logger.fatal(current_user.user_id.to_s + "_users_add")
        format.html { redirect_to @user, notice: '登録作業が完了しました。' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    @user = User.find(params[:id])
  
    respond_to do |format|
      if @user.update(params[:user])
        change_comment = @user.user_id.to_s + ":" + @user.user_name.to_s
        api_log_hists(801, 2, change_comment)
        logger.fatal(current_user.user_id.to_s + "_users_upd")
        format.html { redirect_to @user, notice: '更新処理が完了しました' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.find(params[:id])
    change_comment = @user.user_id.to_s + ":" + @user.user_name.to_s
    @user.destroy
    
    respond_to do |format|
      api_log_hists(801, 3, change_comment)
      logger.fatal(current_user.user_id.to_s + "_users_dlt")
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end
  
  private
  
    def set_combo
      @itaku_codes = MCustom.where("cust_kbn='#{G_CUST_KBN_GYOSHA}' and delete_flg=0").order("cust_code").map{|i| [i.cust_name, i.cust_code] }
      @authoritys = MCombo.where("class_1='#{G_AUTHORITY_CLASS_1}' and delete_flg=0").order("class_2")
    end
end
