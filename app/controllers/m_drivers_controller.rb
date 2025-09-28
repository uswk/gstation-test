class MDriversController < ApplicationController

  before_action :authenticate_user!

  # GET /m_drivers
  def index
    drivercode = params[:search].nil? ? "" : params[:search][:query]
    deleteflg = params[:search].nil? ? "m_drivers.delete_flg=0" : "m_drivers.delete_flg=" + params[:search][:delete]
    @blndelete = params[:search].nil? ? false : params[:search][:delete]=="1" ? true : false
    @bgcolor_td = params[:search].nil? ? "" : params[:search][:delete]=="1" ? "bgcolor=lightgrey" : ""
    if drivercode == ""
      strwhere = deleteflg
    else
      strwhere = deleteflg + " AND driver_code like '%#{drivercode}%'"
    end
    @m_drivers = MDriver
      .joins("LEFT JOIN m_customs mc ON mc.cust_kbn='#{G_CUST_KBN_GYOSHA}' and mc.cust_code=m_drivers.itaku_code")
      .joins("LEFT JOIN m_combos sct ON sct.CLASS_1='#{G_SECTION_CLASS_1}' AND sct.CLASS_2=0 AND sct.CLASS_CODE=m_drivers.SECTION_CODE")
      .page(params[:page]).per("#{G_DEF_PAGE_PER}").where("#{strwhere}").select("m_drivers.*, mc.cust_name, sct.class_name as section_name")

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /m_drivers/1
  def show
    @m_driver = MDriver
      .joins("LEFT JOIN m_customs mc ON mc.cust_kbn='#{G_CUST_KBN_GYOSHA}' and mc.cust_code=m_drivers.itaku_code")
      .joins("LEFT JOIN m_combos sct ON sct.CLASS_1='#{G_SECTION_CLASS_1}' AND sct.CLASS_2=0 AND sct.CLASS_CODE=m_drivers.SECTION_CODE")
      .where(id: params.expect(:id))
      .select("m_drivers.*, mc.cust_name, sct.class_name as section_name").first

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /m_drivers/new
  def new
    @m_driver = MDriver.new
    @itaku_codes = MCustom.where("cust_kbn='#{G_CUST_KBN_GYOSHA}'").order("cust_code asc").map{|i| [i.cust_name, i.cust_code] }
    @section_codes = MCombo.where("class_1='#{G_SECTION_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
    
    @action_form = 'create'
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /m_drivers/1/edit
  def edit
    @m_driver = MDriver.find(params[:id])
    @itaku_codes = MCustom.where("cust_kbn='#{G_CUST_KBN_GYOSHA}'").order("cust_code asc").map{|i| [i.cust_name, i.cust_code] }
    @section_codes = MCombo.where("class_1='#{G_SECTION_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @action_form = 'update'
  end

  # POST /m_drivers
  def create
    @m_driver = MDriver.new(m_driver_params)
    @itaku_codes = MCustom.where("cust_kbn='#{G_CUST_KBN_GYOSHA}'").order("cust_code asc").map{|i| [i.cust_name, i.cust_code] }
    @section_codes = MCombo.where("class_1='#{G_SECTION_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
    
    respond_to do |format|
      if @m_driver.save
        change_comment = @m_driver.driver_code.to_s + ":" + @m_driver.driver_name.to_s
        api_log_hists(602, 1, change_comment)
        format.html { redirect_to @m_driver, notice: '追加処理が完了しました' }
      else
        format.html { render action: 'new' }
      end
    end
  end

  # PATCH/PUT /m_drivers/1
  def update
    @m_driver = MDriver.find(params.expect(:id))
  
    respond_to do |format|
      if @m_driver.update(m_driver_params)
        change_comment = @m_driver.driver_code.to_s + ":" + @m_driver.driver_name.to_s
        api_log_hists(602, 2, change_comment)
        format.html { redirect_to @m_driver, notice: '更新処理が完了しました' }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  # DELETE /m_drivers/1
  def destroy
    @m_driver = MDriver.find(params[:id])
    if @m_driver.delete_flg==1
      @m_driver.update(:delete_flg => 0)
      change_type = 8
    else
      @m_driver.update(:delete_flg => 1)
      change_type = 3
    end
    respond_to do |format|
      change_comment = @m_driver.driver_code.to_s + ":" + @m_driver.driver_name.to_s
      api_log_hists(602, change_type, change_comment)
      format.html { redirect_to m_drivers_url }
    end
  end

  private

  def m_driver_params
    params.expect(m_driver: [:driver_code, :driver_name, :section_code, :itaku_code, :delete_flg])
  end
end
