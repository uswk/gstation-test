class AdminExcelController < ApplicationController

  before_action :authenticate_user!
  
  # GET /admin_excel
  def index
    @admin_types = MCombo.where("class_1='#{G_ADMIN_TYPE_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code")
    @districts = MCombo.where("class_1=? and class_2=0 and delete_flg=0",G_DISTRICT_CLASS_1).order("class_code asc").map{|i| [i.class_name, i.class_code] }
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # POST /admin_excel
  def excel
    
    arrhead = ['管理者ｺｰﾄﾞ', '管理者名','種別','地区','地区名','並び順','住所','ｱﾊﾟｰﾄ･ﾏﾝｼｮﾝ･ﾋﾞﾙ名','Eメール','電話番号','FAX番号']
    if params[:excel_flg]=="2"
      # Excel取り込み
      
      xlsxFile = params[:upload_file][:query]
      kibou_date = params[:kibou_date][:query]
      spst = Roo::Excelx.new(xlsxFile.path, file_warning: :ignore)

      @now_date = Date.today.try(:strftime, "%Y-%m-%d") # 現在の日付を取得
      row_hkn = 0
      add_count = 0
      # トランザクション処理
      begin
        ActiveRecord::Base.transaction do
          spst.first_row.upto(spst.last_row) do |row|
            row_hkn = row
            if row.to_i == 1
              # ヘッダチェック（1件目のみ）
              for iCount in 1..8 do
                if spst.cell(row, iCount).to_s!=arrhead[iCount-1]
                  #ヘッダの内容が違ったら強制エラー
                  @t_change_shinsei = TChangeShinsei.new(:cust_kbn=>nil)
                  @t_change_shinsei.save!
                end
              end
            else
              # 存在チェック
              @customs = MCustom.joins("left join m_combos c on c.class_1='#{G_ADMIN_TYPE_CLASS_1}' and c.class_2=0 and c.class_code=m_customs.admin_type").joins("LEFT JOIN m_combos d ON d.class_1='#{G_DISTRICT_CLASS_1}' AND d.class_2=0 AND d.class_code=m_customs.district_code").where("m_customs.cust_kbn=? and m_customs.cust_code=?", G_CUST_KBN_ADMIN, spst.cell(row, 1)).select("m_customs.*,c.class_name as admin_type_name, d.class_name as district").first
              if @customs.nil?
                #存在しなかったら強制エラー
                @t_change_shinsei = TChangeShinsei.new(:cust_kbn=>nil)
                @t_change_shinsei.save!
              end
              # 変更チェック
              @chg_flg = 0
              if spst.cell(row, 2).to_s!=@customs.cust_name.to_s || spst.cell(row, 5).to_s!=@customs.district_name.to_s || spst.cell(row, 6).to_i.to_s!=@customs.seq.to_i.to_s || spst.cell(row, 7).to_s!=@customs.addr_1.to_s || spst.cell(row, 8).to_s!=@customs.addr_2.to_s || spst.cell(row, 9).to_s!=@customs.email.to_s || spst.cell(row, 10).to_s!=@customs.tel_no.to_s || spst.cell(row, 11).to_s!=@customs.fax_no.to_s
                @chg_flg = 1
              end
              
              #管理者種別
              @admin_type = @customs.admin_type
              if spst.cell(row, 3).to_s!=@customs.admin_type_name.to_s
                #管理者種別が違ったらコード取得
                @combo = MCombo.where("class_1=? and class_2=0 and class_name=?", G_ADMIN_TYPE_CLASS_1, spst.cell(row, 3).to_s).first
                if @combo.nil?
                  #存在しなかったら強制エラー
                  @t_change_shinsei = TChangeShinsei.new(:cust_kbn=>nil)
                  @t_change_shinsei.save!
                else
                  @admin_type = @combo.class_code
                  @chg_flg = 1
                end
              end
              #地区
              @district_code = @customs.district_code
              if spst.cell(row, 4).to_s!=@customs.district.to_s
                #地区が違ったらコード取得
                @combo = MCombo.where("class_1=? and class_2=0 and class_name=?", G_DISTRICT_CLASS_1, spst.cell(row, 4).to_s).first
                if @combo.nil?
                  #存在しなかったら強制エラー
                  @t_change_shinsei = TChangeShinsei.new(:cust_kbn=>nil)
                  @t_change_shinsei.save!
                else
                  @district_code = @combo.class_code
                  @chg_flg = 1
                end
              end
              
              # 追加（少しでも変更がある場合）
              if @chg_flg == 1
                @t_change_shinsei = TChangeShinsei.new(:cust_kbn=>G_CUST_KBN_ADMIN, :cust_code=>spst.cell(row, 1), :admin_type=>@admin_type, :district_code=>@district_code, :district_name=>spst.cell(row, 5), :seq=>spst.cell(row, 6), :cust_name=>spst.cell(row, 2), :addr_1=>spst.cell(row, 7), :addr_2=>spst.cell(row, 8), :tel_no=>spst.cell(row, 10), :fax_no=>spst.cell(row, 11), :email=>spst.cell(row, 9), :shinsei_date=>@now_date, :kibou_date=>kibou_date, :confirm_flg => 0)
                @t_change_shinsei.save!
                add_count = add_count + 1
              end
            end
          end
          #raise ActiveRecord.Rollback
        end
        api_log_hists(1101, 6, "")
        logger.fatal(current_user.user_id.to_s + "_admin_excel_in")
        redirect_to admin_excel_url, notice: "Excelの取込が完了しました。（" + add_count.to_s + "件取込）"
      rescue => e
        logger.fatal(current_user.user_id.to_s + "_admin_excel_in_err")
        redirect_to admin_excel_url, alert: "Excelの取込に失敗しました。　" + row_hkn.to_s + "行目でエラーが発生しました。"
      end
      
    else
      # Excel書き出し
      
      custcode = params[:search].nil? ? "" : params[:search][:query]
      custname = params[:search_name].nil? ? "" : params[:search_name][:query]
      custaddr = params[:search_addr].nil? ? "" : params[:search_addr][:query]
      custtel = params[:search_tel].nil? ? "" : params[:search_tel][:query]
      admintype = params[:search_type].nil? ? "" : params[:search_type][:query]
      district_code = params[:search_district].nil? ? "" : params[:search_district][:query]
      strwhere = " m_customs.delete_flg=0"
      strwhere = strwhere + " and m_customs.cust_kbn='#{G_CUST_KBN_ADMIN}'"
      
      # 管理者ｺｰﾄﾞ
      if custcode != ""
        strwhere = strwhere + " and m_customs.cust_code='#{custcode}'"
      end
      # 管理者名
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
      # 種別
      if admintype != ""
        strwhere = strwhere + " and m_customs.admin_type = '#{admintype}'"
      end
      # 地区
      if district_code != ""
        strwhere = strwhere + " and m_customs.district_code = '#{district_code}'"
      end
      
      @m_customs = MCustom.joins("LEFT JOIN m_combos c ON c.class_1='#{G_ADMIN_TYPE_CLASS_1}' AND c.class_2=0 and c.class_code=m_customs.admin_type").joins("LEFT JOIN m_combos d ON d.class_1='#{G_DISTRICT_CLASS_1}' AND d.class_2=0 and d.class_code=m_customs.district_code").where("#{strwhere}").select("m_customs.*, c.class_name as admin_type_name, d.class_name as district").order("m_customs.admin_type, m_customs.seq, m_customs.cust_code")
      
      pkg = Axlsx::Package.new
      pkg.workbook do |wb|
        wb.add_worksheet(:name => '管理者') do |ws|   # シート名の指定は省略可
          # ヘッダ行
          header_style = ws.styles.add_style :bg_color => "C0C0C0", :border => {:style => :thin, :color => "FF333333"}
          ws.add_row(['管理者ｺｰﾄﾞ', '管理者名','種別','地区','地区名','並び順','住所','ｱﾊﾟｰﾄ･ﾏﾝｼｮﾝ･ﾋﾞﾙ名','Eメール','電話番号','FAX番号'], :style=>header_style)
          # 横幅
          ws.column_widths(11, 50, 9, 9, 9, 6, 40, 40, 22, 14, 14)
          detail_style = ws.styles.add_style :border => {:style => :thin, :color => "FF333333"}
          @m_customs.each do |m_custom|
            ws.add_row([m_custom.cust_code, m_custom.cust_name, m_custom.admin_type_name, m_custom.district, m_custom.district_name, m_custom.seq, m_custom.addr_1, m_custom.addr_2, m_custom.email, m_custom.tel_no, m_custom.fax_no], :types => [:string, :string, :string, :string, :string, :integer, :string, :string, :string, :string, :string], :style=>detail_style)
          end
        end
      end
      if (/MSIE/ =~ request.user_agent) || (/Trident/ =~ request.user_agent) || (/Edge/ =~ request.user_agent)
        send_data(pkg.to_stream.read, 
          :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          :filename => "管理者情報.xlsx".encode('Shift_JIS'))
      else
        send_data(pkg.to_stream.read, 
          :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          :filename => "管理者情報.xlsx")
      end
      api_log_hists(1101, 5, "")
      logger.fatal(current_user.user_id.to_s + "_admin_excel_out")
    end
  end
  
  
end
