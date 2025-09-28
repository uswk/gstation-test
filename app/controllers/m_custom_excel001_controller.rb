class MCustomExcel001Controller < ApplicationController

  before_action :authenticate_user!
  
  # GET /m_custom_excel001
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # POST /m_custom_excel001
  def excel
    require 'kconv' #文字コード操作をよろしくやるライブラリ
    require 'geocoder'
    
    Geocoder.configure(:language => :ja, :units => :km )
    
    arrhead = ['ｽﾃｰｼｮﾝｺｰﾄﾞ','ステーション名','住所','ｱﾊﾟｰﾄ･ﾏﾝｼｮﾝ･ﾋﾞﾙ名','利用内容','利用世帯数','利用人数','備考','管理者名','収集区','申請区分']
    arrshinsei = {'新設'=>1, '変更'=>2, '廃止'=>3}

      # Excel書き出し
      
      custcode = params[:search].nil? ? "" : params[:search][:query]
      custname = params[:search_name].nil? ? "" : params[:search_name][:query]
      custaddr = params[:search_addr].nil? ? "" : params[:search_addr][:query]
      custadmin = params[:search_admin].nil? ? "" : params[:search_admin][:query]
      strwhere = " m_customs.delete_flg=0"
      strwhere = strwhere + " and m_customs.cust_kbn='#{G_CUST_KBN_STATION}'"
      
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
      
      @m_customs = MCustom.joins("left join m_customs admin on admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code")
      @m_customs = @m_customs.joins("left join (select mrp.cust_kbn, mrp.cust_code, mrp.route_code from m_route_points mrp inner join m_routes mr on mr.route_code=mrp.route_code where mr.delete_flg=0 group by mrp.cust_kbn, mrp.cust_code, mrp.route_code) mrp on mrp.cust_kbn=m_customs.cust_kbn and mrp.cust_code=m_customs.cust_code")
      @m_customs = @m_customs.joins("left join m_routes mr on mr.route_code=mrp.route_code")
      @m_customs = @m_customs.joins("left join (select mrp.cust_kbn, mrp.cust_code, count(*) as route_count from m_route_points mrp inner join m_routes mr on mr.route_code=mrp.route_code where mr.delete_flg=0 group by mrp.cust_kbn, mrp.cust_code) mrp2 on mrp2.cust_kbn=m_customs.cust_kbn and mrp2.cust_code=m_customs.cust_code")
      @m_customs = @m_customs.joins("left join m_combos c1 on c1.class_1='#{G_USE_CONTENT_CLASS_1}' and c1.class_2=0 and c1.class_code=m_customs.use_content")
      @m_customs = @m_customs.joins("left join (select route_code, itaku_code, max(itaku.cust_name) as itaku_name from m_route_rundates mrr2 left join m_customs itaku on itaku.cust_kbn='#{G_CUST_KBN_GYOSHA}' and itaku.cust_code=mrr2.itaku_code where itaku_code is not null and itaku_code<>'' group by route_code, itaku_code) mrr2 on mrr2.route_code=mrp.route_code")
      @m_customs = @m_customs.where("#{strwhere}")
      @m_customs = @m_customs.select("m_customs.*, admin.cust_name as admin_name, mrp.route_code, mr.route_name, c1.class_name as use_content_name, mrp2.route_count, group_concat(DISTINCT concat(mrr2.itaku_name) ORDER BY mrr2.route_code, mrr2.itaku_code SEPARATOR ' 、') as itaku_name")
      @m_customs = @m_customs.group("m_customs.cust_code, mrp.route_code")
      @m_customs = @m_customs.order("m_customs.cust_code, mrp.route_code")
      
      pkg = Axlsx::Package.new
      pkg.workbook do |wb|
        wb.add_worksheet(:name => 'ステーション') do |ws|   # シート名の指定は省略可
          # ヘッダ行
          header_style = ws.styles.add_style :bg_color => "C0C0C0", :border => {:style => :thin, :color => "FF333333"}
          ws.add_row(['ｽﾃｰｼｮﾝｺｰﾄﾞ', 'ステーション名','住所','ｱﾊﾟｰﾄ･ﾏﾝｼｮﾝ･ﾋﾞﾙ名','利用内容','利用世帯数','利用人数','備考','管理者名','収集区','委託会社','件数'], :style=>header_style)
          # 横幅
          ws.column_widths(11, 50, 40, 40, 20, 5, 5, 50, 40, 40, 10)
          detail_style = ws.styles.add_style :border => {:style => :thin, :color => "FF333333"}
          @m_customs.each do |m_custom|
            ws.add_row([m_custom.cust_code, m_custom.cust_name, m_custom.addr_1, m_custom.addr_2, m_custom.use_content_name, m_custom.setai_count, m_custom.use_count, m_custom.memo, m_custom.admin_name, m_custom.route_name, m_custom.itaku_name, m_custom.route_count], :types => [:string, :string, :string, :string, :string, :integer, :integer, :string, :string, :string, :string, :integer], :style=>detail_style)
          end
        end
      end
      if (/MSIE/ =~ request.user_agent) || (/Trident/ =~ request.user_agent) || (/Edge/ =~ request.user_agent)
        send_data(pkg.to_stream.read, 
          :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          :filename => "ステーション情報.xlsx".encode('Shift_JIS'))
      else
        send_data(pkg.to_stream.read, 
          :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          :filename => "ステーション情報.xlsx")
      end
      api_log_hists(1002, 5, "")
      logger.fatal(current_user.user_id.to_s + "_m_custom_excel_out")
    end

end
