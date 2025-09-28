class MMailSettingsController < ApplicationController

  before_action :authenticate_user!

  # GET /m_mail_settings
  def index
    
    @m_combo = MCombo.where("class_1=0 and class_2=0 and class_code=2").first
    @m_mail_setting = MMailSetting.where("1=1").first
    
    if @m_mail_setting.nil?
      @setting_kbn = 1
      @user_name = '未設定です'
      @mail_pass = '未設定です'
      @address = '未設定です'
      @domain = '未設定です'
      @port = '未設定です'
      @authentication = 0
      @display_name = '未設定です'
      @reply_to_mail = '未設定です'
      @update_flg = 1
    else
      @setting_kbn = @m_mail_setting.setting_kbn
      @user_name = @m_mail_setting.user_name
      @mail_pass = @m_mail_setting.mail_pass
      @address = @m_mail_setting.address
      @domain = @m_mail_setting.domain
      @port = @m_mail_setting.port
      @authentication = @m_mail_setting.authentication
      @display_name = @m_mail_setting.display_name
      @reply_to_mail = @m_mail_setting.reply_to_mail
      @update_flg = 2
    end
    @m_combo_authentication = MCombo.where("class_1=? and class_2=0 and class_code=?", G_MAIL_AUTHENTICATION, @authentication).first
  end

  # GET /m_mail_settings/new
  def new
    @m_combo = MCombo.where("class_1=0 and class_2=0 and class_code=2").first
    @m_combo_authentications = MCombo.where("class_1=? and class_2=0", G_MAIL_AUTHENTICATION).order("class_1,class_2,class_code")

    #基本設定用
    @user_name = @m_combo.value
    @mail_pass = @m_combo.value2
    @address = @m_combo.value3
    @domain = @m_combo.value4
    @port = @m_combo.value5
    @authentication = 0
    @readonly_type = ""
    
    @m_mail_setting = MMailSetting.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /m_mail_settings/edit
  def edit
    
    @m_combo = MCombo.where("class_1=0 and class_2=0 and class_code=2").first
    @m_combo_authentications = MCombo.where("class_1=? and class_2=0", G_MAIL_AUTHENTICATION).order("class_1,class_2,class_code")

    #基本設定用
    @user_name = @m_combo.value
    @mail_pass = @m_combo.value2
    @address = @m_combo.value3
    @domain = @m_combo.value4
    @port = @m_combo.value5
    @authentication = 0
    
    @m_mail_setting = MMailSetting.where("1=1").first
    if @m_mail_setting.setting_kbn==1
      @readonly_type = " readonly=true"
    else
      @readonly_type = ""
    end
  end
  
  # POST /m_mail_settings
  def create
    
    @m_mail_setting = MMailSetting.new(m_mail_settings_params)

    respond_to do |format|
      if @m_mail_setting.save
        api_log_hists(1401, 1, "")
        logger.fatal(current_user.user_id.to_s + "_m_mail_settings_add")
        format.html { redirect_to :action => "index", notice: '追加処理が完了しました' }
      else
        format.html { render action: 'new' }
      end
    end
  end

  # PATCH/PUT /m_mail_settings/1
  def update
    @m_mail_setting = MMailSetting.find(params[:id])

    respond_to do |format|
      if @m_mail_setting.update(m_mail_settings_params)
        api_log_hists(1401, 2, "")
        logger.fatal(current_user.user_id.to_s + "_m_mail_settiong_upd")
        format.html { redirect_to :action => "index", notice: '更新処理が完了しました' }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  private

  def m_mail_settings_params()
    params.expect(m_mail_setting: [:setting_kbn, :user_name, :mail_pass, :address, :domain, :port, :authentication, :last_up_user, :created_at, :updated_at, :display_name, :reply_to_mail])
  end
end
