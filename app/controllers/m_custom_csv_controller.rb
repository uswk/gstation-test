class MCustomCsvController < ApplicationController

  before_action :authenticate_user!
  
  # GET /m_custom_csv
  def index
  
    # 収集区
    routewhere = ""
    if current_user.itaku_code.blank?
      routewhere = "m_routes.delete_flg = 0"
    else
      routewhere = "m_routes.delete_flg = 0 and mrr.itaku_code = '#{current_user.itaku_code}'"
    end
    @route_codes = MRoute.joins("left join m_route_rundates mrr on mrr.route_code=m_routes.route_code")
    @route_codes = @route_codes.where("#{routewhere}").group("m_routes.route_code, m_routes.route_name").order("m_routes.route_code asc").map{|i| [i.route_code.to_s + ':' + i.route_name.to_s, i.route_code] }
    @route_codes = @route_codes + ['未設定']
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # POST /m_custom_csv
  def csv
    require 'kconv'
    require 'csv'
    
    custcode = params[:search].nil? ? "" : params[:search][:query]
    custname = params[:search_name].nil? ? "" : params[:search_name][:query]
    custaddr = params[:search_addr].nil? ? "" : params[:search_addr][:query]
    custadmin = params[:search_admin].nil? ? "" : params[:search_admin][:query]
    custroute = params[:search_route].nil? ? "" : params[:search_route][:query]
    strselect = "m_customs.cust_code, m_customs.cust_name, m_customs.addr_1, m_customs.addr_2, m_customs.latitude, m_customs.longitude, m_customs.use_content, m_customs.setai_count, m_customs.use_count, m_customs.memo, m_customs.shinsei_date, m_customs.start_date, m_customs.haishi_date, m_customs.end_date, admin.cust_code as admin_code, admin.cust_name as admin_name, admin.tel_no as admin_tel, admin.email as admin_email, c.class_name as use_content_name"
    strwhere = " m_customs.delete_flg=0"
    strwhere = strwhere + " and m_customs.cust_kbn='#{G_CUST_KBN_STATION}'"
    @m_customs = MCustom.joins("LEFT JOIN m_customs admin ON admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code")
    
    # ｽﾃｰｼｮﾝｺｰﾄﾞ
    if custcode != ""
      strwhere = strwhere + " and m_customs.cust_code='#{custcode}'"
    end
    # ステーション名
    if custname != ""
      strwhere = strwhere + " and m_customs.cust_name like '%#{custname}%'"
    end
    # 住所
    if custaddr != ""
      strwhere = strwhere + " and m_customs.addr_1 like '%#{custaddr}%'"
    end
    # 管理者名
    if custadmin != ""
      strwhere = strwhere + " and admin.cust_name like '%#{custadmin}%'"
    end

    # 収集区
    if custroute != ""
      if custroute.to_s=="未設定"
        strwhere = strwhere + " and route.route_code is null"
      else
        strwhere = strwhere + " and route.route_code = '#{custroute}'"
      end
      @m_customs = @m_customs.joins("LEFT JOIN m_route_points route ON route.cust_kbn=m_customs.cust_kbn AND route.cust_code=m_customs.cust_code")
    end
    
    @m_customs = @m_customs.joins("LEFT JOIN m_combos c ON c.class_1='#{G_USE_CONTENT_CLASS_1}' AND c.class_2=0 and c.class_code=m_customs.use_content").where("#{strwhere}").select("#{strselect}").order("m_customs.cust_code")
    #@m_customs = MCustom.joins("LEFT JOIN m_customs admin ON admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code").joins("LEFT JOIN m_route_points route ON route.cust_kbn=m_customs.cust_kbn AND route.cust_code=m_customs.cust_code").where("#{strwhere}").select("#{strselect}").order("m_customs.cust_code")
    
    file_name = Kconv.kconv("m_custom.csv", Kconv::SJIS)
    header = ["ｽﾃｰｼｮﾝｺｰﾄﾞ", "ステーション名","住所","ｱﾊﾟｰﾄ・ﾏﾝｼｮﾝ名","緯度","経度","管理者ｺｰﾄﾞ","管理者名","電話番号","ﾒｰﾙｱﾄﾞﾚｽ","使用内容","利用世帯数","利用人数","備考","申請日","収集開始日","廃止届出受付日","集配停止日"]
    csv_data = CSV.generate("", :row_sep => "\r\n", :headers => header, :write_headers => true) do |csv|
      @m_customs.each do |m_custom|
        shinsei_date =  m_custom.shinsei_date.nil? ? "" : m_custom.shinsei_date.strftime("%Y/%m/%d")
        start_date = m_custom.start_date.nil? ? "" : m_custom.start_date.strftime("%Y/%m/%d")
        haishi_date = m_custom.haishi_date.nil? ? "" : m_custom.haishi_date.strftime("%Y/%m/%d")
        end_date = m_custom.end_date.nil? ? "" : m_custom.end_date.strftime("%Y/%m/%d")
        column = []
        column << m_custom.cust_code
        column << m_custom.cust_name
        column << m_custom.addr_1
        column << m_custom.addr_2
        column << m_custom.latitude
        column << m_custom.longitude
        column << m_custom.admin_code
        column << m_custom.admin_name
        column << m_custom.admin_tel
        column << m_custom.admin_email
        column << m_custom.use_content_name
        column << m_custom.setai_count
        column << m_custom.use_count
        column << m_custom.memo
        column << shinsei_date
        column << start_date
        column << haishi_date
        column << end_date
        csv << column
      end
    end
    csv_data = csv_data.tosjis
    if (/MSIE/ =~ request.user_agent) || (/Trident/ =~ request.user_agent) || (/Edge/ =~ request.user_agent)
      send_data(csv_data, type: 'text/csv; charset=shift_jis;', filename: "ステーション情報.csv".encode('Shift_JIS'))
    else
      send_data(csv_data, type: 'text/csv; charset=shift_jis;', filename: "ステーション情報.csv")
    end
    api_log_hists(1001, 5, "")
    logger.fatal(current_user.user_id.to_s + "_m_custom_csv_out")
  end
end
