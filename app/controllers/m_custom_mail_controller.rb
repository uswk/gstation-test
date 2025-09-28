class MCustomMailController < ApplicationController

  before_action :authenticate_user!

  # GET /m_custom_mail
  def index
 
    custcode = params[:search].nil? ? "" : params[:search][:query]
    custname = params[:search_name].nil? ? "" : params[:search_name][:query]
    custtype = params[:search_type].nil? ? "" : params[:search_type][:query]
    custaddr = params[:search_addr].nil? ? "" : params[:search_addr][:query]
    custemail = params[:search_email].nil? ? "" : params[:search_email][:query]
    @bln_all = params[:search_all].nil? ? false : params[:search_all][:query]=="1" ? true : false
    strwhere = "m_customs.delete_flg=0 and ((m_customs.email is not null and m_customs.email<>'') and m_customs.cust_kbn='#{G_CUST_KBN_ADMIN}')"
    # 管理者ｺｰﾄﾞ
    if custcode != ""
      strwhere = strwhere + " and m_customs.cust_code='#{custcode}'"
    end
    # 管理者名
    if custname != ""
      strwhere = strwhere + " and m_customs.cust_name like '%#{custname}%'"
    end
    # 管理者種別
    if custtype != ""
      strwhere = strwhere + " and m_customs.admin_type = '#{custtype}'"
    end
    # 住所
    if custaddr != ""
      strwhere = strwhere + " and m_customs.addr_1 like '%#{custaddr}%'"
    end
    # メールアドレス
    if custemail != ""
      strwhere = strwhere + " and m_customs.email like '%#{custemail}%'"
    end
    @m_custom_mails = MCustom.joins("LEFT JOIN m_combos mc ON mc.CLASS_1='#{G_ADMIN_TYPE_CLASS_1}' AND mc.CLASS_2=0 AND mc.CLASS_CODE=m_customs.admin_type").where("#{strwhere}").select("m_customs.*,mc.class_name as type_name").order("m_customs.cust_code")
    if @bln_all==false
      @m_custom_mails = @m_custom_mails.page(params[:page]).per("#{G_DEF_PAGE_PER}")
    end
    @admin_types = MCombo.where("class_1='#{G_ADMIN_TYPE_CLASS_1}' AND class_2=0").order("class_code").map{|i| [i.class_name, i.class_code] }

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /m_custom_mail/1
  def show
    @t_mail_hists = TMailHist.joins("INNER JOIN m_customs mc ON mc.cust_kbn=t_mail_hists.cust_kbn AND mc.cust_code=t_mail_hists.cust_code").page(params[:page]).per("#{G_DEF_PAGE_PER}").where("mc.id=?", params[:id]).select("t_mail_hists.*, mc.id as mc_id").order("t_mail_hists.send_date DESC")
    
    #添付ファイルのダウンロード
    if not params[:mail_hist_id].nil?
      @t_mail_hist = TMailHist.find(params[:mail_hist_id])
      @download_file = @t_mail_hist.send_file.to_s + "/" + params[:file_name].to_s
      send_file @download_file.encode, filename: params[:file_name].encode('Shift_JIS')
    end
    
    #respond_to do |format|
    #  format.html # show.html.erb
    #end
  end

  # POST /m_custom_mail
  def mail

    @subject_txt = params[:subject_txt]
    @message_txt = params[:message_txt]
    strwhere = "cust_kbn='#{G_CUST_KBN_ADMIN}' and cust_code in ("
    params[:mail_chk].length.times do |i|
      if i!=0
        strwhere = strwhere + ","
      end
      strwhere = strwhere + "'" + params[:mail_chk][i].to_s + "'"
    end
    strwhere = strwhere + ")"
    @m_customs = MCustom.joins("LEFT JOIN m_combos mc ON mc.CLASS_1='#{G_ADMIN_TYPE_CLASS_1}' AND mc.CLASS_2=0 AND mc.CLASS_CODE=m_customs.admin_type").where("#{strwhere}").select("m_customs.*,mc.class_name as type_name").order("m_customs.cust_code")
    
    case params[:next_flg][0]
      when "1" then
        @next_flg="2"
        @original_name = ""
        @send_path = ""
        if (not params[:send_file_all].nil?) && params[:send_file_all] != ""
          send_file = params[:send_file_all]
          send_date = Time.now.strftime('%Y%m%d%H%M%S')
          @original_name = send_file.original_filename
          @send_path = "#{Rails.root}/public/images/mail/#{send_date}"
          FileUtils.mkdir_p(@send_path) unless FileTest.exist?(@send_path)
          File.open("#{@send_path}/#{@original_name}", 'wb') { |f| f.write(send_file.read) }
        end
      when "2" then
        # SMTP設定
        @m_mail_setting = MMailSetting.joins("LEFT JOIN m_combos mc ON mc.class_1='#{G_MAIL_AUTHENTICATION}' and mc.class_2=0 and mc.class_code=m_mail_settings.authentication").select("m_mail_settings.*, mc.class_name as authentication_name").first
        if @m_mail_setting.nil?
          @smtp_user_name = ""
          @smtp_password = ""
          @smtp_address = ""
          @smtp_domain = ""
          @smtp_port = ""
          @smtp_authentication = ""
          @smtp_display_name = ""
          @smtp_reply_to_mail = ""
        else
          @smtp_user_name = @m_mail_setting.user_name
          @smtp_password = @m_mail_setting.mail_pass
          @smtp_address = @m_mail_setting.address
          @smtp_domain = @m_mail_setting.domain
          @smtp_port = @m_mail_setting.port
          @smtp_authentication = @m_mail_setting.authentication_name
          @smtp_display_name = @m_mail_setting.display_name
          @smtp_reply_to_mail = @m_mail_setting.reply_to_mail.blank? ? @m_mail_setting.user_name : @m_mail_setting.reply_to_mail
        end
logger.fatal(ActionMailer::Base.smtp_settings)
        ActionMailer::Base.raise_delivery_errors = true
        ActionMailer::Base.default_url_options={:host=>'localhost:3000'}
        ActionMailer::Base.delivery_method = :smtp
        ActionMailer::Base.smtp_settings = {
          :address => @smtp_address.to_s,
          :port => @smtp_port.to_s,
          :domain => @smtp_domain.to_s,
          :user_name => @smtp_user_name.to_s,
          :password => @smtp_password.to_s,
          :authentication => @smtp_authentication.to_s,
          :enable_starttls_auto => true, #todo
        }
logger.fatal(ActionMailer::Base.smtp_settings)
        @next_flg="3"
        if (not params[:original_name].nil?) && params[:original_name] != ""
          @send_file = "#{params[:send_path]}/#{params[:original_name]}"
          @original_name = params[:original_name]
        else
          @send_file = ""
          @original_name = ""
        end
        params[:mail_chk].length.times do |i|
          #メール送信
          @send_subject = @subject_txt.gsub("{@管理者名}", params[:send_cust_name][i])
          @send_body = @message_txt.gsub("{@管理者名}", params[:send_cust_name][i])
          @mail = NoticeMailer.sendmail_confirm("#{@send_body}","#{@send_subject}","#{params[:send_email][i]}","#{@smtp_user_name}","#{@send_file}","#{@original_name}","#{@smtp_display_name}","#{@smtp_reply_to_mail}").deliver_later
          #送信履歴追加
          @t_mail_hist = TMailHist.new(:cust_kbn => G_CUST_KBN_ADMIN, :cust_code=> params[:mail_chk][i], :send_date => Time.now, :send_subject => @send_subject, :send_body => @send_body, :send_file => params[:send_path], :send_email => params[:send_email][i], :delete_flg => 0)
          @t_mail_hist.save
          api_log_hists(901, 5, "")
          logger.fatal(current_user.user_id.to_s + "_m_custom_mail_send")
        end
      else
    end
  end
end
