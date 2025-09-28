class MCarsController < ApplicationController

  before_action :authenticate_user!

  # GET /m_cars
  # GET /m_cars.json
  def index
    carcode = params[:search].nil? ? "" : params[:search][:query]
    deleteflg = params[:search].nil? ? "m_cars.delete_flg=0" : "m_cars.delete_flg=" + params[:search][:delete]
    @blndelete = params[:search].nil? ? false : params[:search][:delete]=="1" ? true : false
    @bgcolor_td = params[:search].nil? ? "" : params[:search][:delete]=="1" ? "bgcolor=lightgrey" : ""
    if carcode == ""
      strwhere = deleteflg
    else
      strwhere = deleteflg + " AND car_code like '%#{carcode}%'"
    end
    @m_cars = MCar.joins("LEFT JOIN m_customs mc ON mc.cust_kbn='#{G_CUST_KBN_GYOSHA}' and mc.cust_code=m_cars.itaku_code")
      .joins("LEFT JOIN m_combos sct ON sct.CLASS_1='#{G_SECTION_CLASS_1}' AND sct.CLASS_2=0 AND sct.CLASS_CODE=m_cars.SECTION_CODE")
      .joins("LEFT JOIN m_combos typ ON typ.CLASS_1='#{G_CAR_TYPE_CLASS_1}' AND typ.CLASS_2=0 AND typ.CLASS_CODE=m_cars.TYPE_CODE")
      .page(params[:page]).per("#{G_DEF_PAGE_PER}")
      .where("#{strwhere}").select("m_cars.*, mc.cust_name, sct.class_name as section_name, typ.class_name as type_name")

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @m_cars }
    end
  end

  # GET /m_cars/1
  # GET /m_cars/1.json
  def show
    @m_car = MCar.joins("LEFT JOIN m_customs mc ON mc.cust_kbn='#{G_CUST_KBN_GYOSHA}' and mc.cust_code=m_cars.itaku_code")
      .joins("LEFT JOIN m_combos sct ON sct.CLASS_1='#{G_SECTION_CLASS_1}' AND sct.CLASS_2=0 AND sct.CLASS_CODE=m_cars.SECTION_CODE")
      .joins("LEFT JOIN m_combos typ ON typ.CLASS_1='#{G_CAR_TYPE_CLASS_1}' AND typ.CLASS_2=0 AND typ.CLASS_CODE=m_cars.TYPE_CODE")
      .select("m_cars.*, mc.cust_name, sct.class_name as section_name, typ.class_name as type_name")
      .where(id: params[:id]).first
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @m_car }
    end
  end

  # GET /m_cars/new
  def new
    @m_car = MCar.new
    @itaku_codes = MCustom.where("cust_kbn='#{G_CUST_KBN_GYOSHA}'").order("cust_code asc").map{|i| [i.cust_name, i.cust_code] }
    @section_codes = MCombo.where("class_1='#{G_SECTION_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @type_codes = MCombo.where("class_1='#{G_CAR_TYPE_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
    
    @action_form = 'create'
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @m_car }
    end
  end

  # GET /m_cars/1/edit
  def edit
    @m_car = MCar.find(params[:id])
    @itaku_codes = MCustom.where("cust_kbn='#{G_CUST_KBN_GYOSHA}'").order("cust_code asc").map{|i| [i.cust_name, i.cust_code] }
    @section_codes = MCombo.where("class_1='#{G_SECTION_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @type_codes = MCombo.where("class_1='#{G_CAR_TYPE_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @action_form = 'update'
  end

  # POST /m_cars
  # POST /m_cars.json
  def create
    @m_car = MCar.new(m_car_params)
    @itaku_codes = MCustom.where("cust_kbn='#{G_CUST_KBN_GYOSHA}'").order("cust_code asc").map{|i| [i.cust_name, i.cust_code] }
    @section_codes = MCombo.where("class_1='#{G_SECTION_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @type_codes = MCombo.where("class_1='#{G_CAR_TYPE_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
    
    respond_to do |format|
      if @m_car.save
        change_comment = @m_car.car_code.to_s + ":" + @m_car.car_reg_code.to_s
        api_log_hists(601, 1, change_comment)
        logger.fatal(current_user.user_id.to_s + "m_cars_add")
        format.html { redirect_to @m_car, notice: '追加処理が完了しました' }
        format.json { render action: 'show', status: :created, location: @m_car }
      else
        format.html { render action: 'new' }
        format.json { render json: @m_car.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /m_cars/1
  # PATCH/PUT /m_cars/1.json
  def update
    @m_car = MCar.find(params[:id])
  
    respond_to do |format|
      if @m_car.update(m_car_params)
        change_comment = @m_car.car_code.to_s + ":" + @m_car.car_reg_code.to_s
        api_log_hists(601, 2, change_comment)
        logger.fatal(current_user.user_id.to_s + "_m_cars_upd")
        format.html { redirect_to @m_car, notice: '更新処理が完了しました' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @m_car.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /m_cars/1
  # DELETE /m_cars/1.json
  def destroy
    @m_car = MCar.find(params[:id])
    if @m_car.delete_flg==1
      @m_car.update(:delete_flg => 0)
      change_type = 8
    else
      @m_car.update(:delete_flg => 1)
      change_type = 3
    end
    respond_to do |format|
      change_comment = @m_car.car_code.to_s + ":" + @m_car.car_reg_code.to_s
      api_log_hists(601, change_type, change_comment)
      logger.fatal(current_user.user_id.to_s + "_m_cars_dlt")
      format.html { redirect_to m_cars_url }
      format.json { head :no_content }
    end
  end

  private

  def m_car_params
    params.expect(m_car: [:car_code, :car_reg_code, :section_code, :car_maker, :type_code, :itaku_code, :delete_flg])
  end
end
