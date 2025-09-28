class MCustomExcelController < ApplicationController

  before_action :authenticate_user!
  
  # GET /m_custom_excel
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # POST /m_custom_excel
  def excel
    require 'kconv' #文字コード操作をよろしくやるライブラリ
    require 'geocoder'
    
    Geocoder.configure(:language => :ja, :units => :km )
    
    arrhead = ['ｽﾃｰｼｮﾝｺｰﾄﾞ','ステーション名','住所','ｱﾊﾟｰﾄ･ﾏﾝｼｮﾝ･ﾋﾞﾙ名','利用内容','利用世帯数','利用人数','備考','管理者名','収集区','申請区分']
    arrshinsei = {'新設'=>1, '変更'=>2, '廃止'=>3}
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
              for iCount in 1..11 do
                if spst.cell(row, iCount).to_s!=arrhead[iCount-1]
                  #ヘッダの内容が違ったら強制エラー
                  @t_change_shinsei = TChangeShinsei.new(:cust_kbn=>nil)
                  @t_change_shinsei.save!
                end
              end
            else
              # 申請区分チェック
              if spst.cell(row, 11).to_s!='新設' && spst.cell(row, 11).to_s!='変更' && spst.cell(row, 11).to_s!='廃止'
                #存在しなかったら強制エラー
                @t_change_shinsei = TChangeShinsei.new(:cust_kbn=>nil)
                @t_change_shinsei.save!
              end
              # 存在チェック
              @customs = MCustom.joins("left join m_customs admin on admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code").joins("left join m_combos c1 on c1.class_1='#{G_USE_CONTENT_CLASS_1}' and c1.class_2=0 and c1.class_code=m_customs.use_content").joins("left join (select cust_kbn, cust_code, max(route_code) as route_code from m_route_points group by cust_kbn, cust_code) mrp on mrp.cust_kbn=m_customs.cust_kbn and mrp.cust_code=m_customs.cust_code").joins("left join m_routes mr on mr.route_code=mrp.route_code").where("m_customs.cust_kbn=? and m_customs.cust_code=?", G_CUST_KBN_STATION, spst.cell(row, 1)).select("m_customs.*, c1.class_name as use_content_name, admin.cust_name as admin_name, mrp.route_code, mr.route_name").first
              if @customs.nil?
                #存在しなかったら強制エラー
                @t_change_shinsei = TChangeShinsei.new(:cust_kbn=>nil)
                @t_change_shinsei.save!
              end
              
              # 変更チェック
              @chg_flg = 0
              if spst.cell(row, 2).to_s!=@customs.cust_name.to_s || spst.cell(row, 4).to_s!=@customs.addr_2.to_s || spst.cell(row, 8).to_s.gsub(/(\r\n|\r|\n)/, "\n")!=@customs.memo.to_s.gsub(/(\r\n|\r|\n)/, "\n")
                @chg_flg = 1
              end
              
              # 住所（緯度・経度取得）
              @latitude = @customs.latitude
              @longitude = @customs.longitude
              if spst.cell(row, 3).to_s!=@customs.addr_1.to_s
                @latitude = nil
                @longitude = nil
                @latlng_flg = 0
                # 読み込み失敗を考慮して読み取れるまでループ。３回読み取れなかったらエラー
                for num in 1..3 do
                  @latlng = Geocoder.search(spst.cell(row, 3).to_s)
                  @latlng = @latlng.to_s.gsub(' ','')
                  @latlng = @latlng.to_s.gsub('\n', '')
                  @latlng = @latlng.to_s.split('"location"=>')[1]
                  @latitude = @latlng.to_s.split('"lat"=>')[1]
                  @latitude = @latitude.to_s.split(',')[0]
                  @longitude = @latlng.to_s.split('"lng"=>')[1]
                  @longitude = @longitude.to_s.split('}')[0]
                  if not @latitude.blank?
                    @latlng_flg = 1
                    break;
                  end
                end
                # 取得できなかったら強制エラー
                if @latlng_flg == 0
                  @t_change_shinsei = TChangeShinsei.new(:cust_kbn=>nil)
                  @t_change_shinsei.save!
                else
                  @chg_flg = 1
                end
              end
              
              # 使用内容
              @use_content = @customs.use_content
              if spst.cell(row, 5).to_s!=@customs.use_content_name.to_s
                #使用内容が違ったらコード取得
                if spst.cell(row, 5).blank?
                  @use_content = nil
                  @chg_flg = 1
                else
                  @content = MCombo.where("class_1=? and class_2=0 and class_name=? and delete_flg=0", G_USE_CONTENT_CLASS_1, spst.cell(row, 5).to_s).first
                  if @content.nil?
                    #存在しなかったら強制エラー
                    @t_change_shinsei = TChangeShinsei.new(:cust_kbn=>nil)
                    @t_change_shinsei.save!
                  else
                    @use_content = @content.class_code
                    @chg_flg = 1
                  end
                end
              end
              
              # 利用世帯数
              if spst.cell(row, 6).to_s=~ /\A-?\d+(.\d+)?\Z/ || spst.cell(row, 6).blank?
                if spst.cell(row, 6).to_i!=@customs.setai_count.to_i
                  @chg_flg = 1
                end
              else
                # 取得できなかったら強制エラー
                @t_change_shinsei = TChangeShinsei.new(:cust_kbn=>nil)
                @t_change_shinsei.save!
              end

              # 利用人数
              if spst.cell(row, 7).to_s=~ /\A-?\d+(.\d+)?\Z/ || spst.cell(row, 7).blank?
                if spst.cell(row, 7).to_i!=@customs.use_count.to_i
                  @chg_flg = 1
                end
              else
                # 取得できなかったら強制エラー
                @t_change_shinsei = TChangeShinsei.new(:cust_kbn=>nil)
                @t_change_shinsei.save!
              end
              
              # 管理者名
              @admin_code = @customs.admin_code
              if spst.cell(row, 9).to_s!=@customs.admin_name.to_s
                #管理者名が違ったらコード取得
                if spst.cell(row, 9).blank?
                  @admin_code = nil
                  @chg_flg = 1
                else
                  @admin = MCustom.where("cust_kbn=? and cust_name=? and delete_flg=0", G_CUST_KBN_ADMIN, spst.cell(row, 9).to_s).first
                  if @admin.nil?
                    #存在しなかったら強制エラー
                    @t_change_shinsei = TChangeShinsei.new(:cust_kbn=>nil)
                    @t_change_shinsei.save!
                  else
                    @admin_code = @admin.cust_code
                    @chg_flg = 1
                  end
                end
              end
              
              # 収集区
              @route_code = @customs.route_code
              if spst.cell(row, 10).to_s!=@customs.route_name.to_s
                #収集区が違ったらコード取得
                if spst.cell(row, 10).blank?
                  @admin_code = nil
                  @chg_flg = 1
                else
                  @route = MRoute.where("route_name=? and delete_flg=0", spst.cell(row, 10).to_s).first
                  if @route.nil?
                    #存在しなかったら強制エラー
                    @t_change_shinsei = TChangeShinsei.new(:cust_kbn=>nil)
                    @t_change_shinsei.save!
                  else
                    @route_code = @route.route_code
                    @chg_flg = 1
                  end
                end
              end
              
              # 追加（少しでも変更がある場合）
              if @chg_flg == 1 || (spst.cell(row, 11).to_s=='新設' || spst.cell(row, 11).to_s=='廃止')
                @t_change_shinsei = TChangeShinsei.new(:cust_kbn=>G_CUST_KBN_STATION, :cust_code=>spst.cell(row, 1), :cust_name=>spst.cell(row, 2), :addr_1=>spst.cell(row, 3), :addr_2=>spst.cell(row, 4), :latitude=>@latitude, :longitude=>@longitude, :use_content=>@use_content, :setai_count=>spst.cell(row, 6), :use_count=>spst.cell(row, 7), :memo=>spst.cell(row, 8), :admin_code=>@admin_code, :route_code=>@route_code, :shinsei_kbn=>arrshinsei[spst.cell(row, 11).to_s], :shinsei_date=>@now_date, :kibou_date=>kibou_date, :confirm_flg => 0)
                @t_change_shinsei.save!
                add_count = add_count + 1
              end
            end
          end
          #raise ActiveRecord.Rollback
        end
        api_log_hists(1101, 6, "")
        logger.fatal(current_user.user_id.to_s + "_m_custom_excel_in")
        redirect_to m_custom_excel_url, notice: "Excelの取込が完了しました。（" + add_count.to_s + "件取込）"
      rescue => e
        logger.fatal(current_user.user_id.to_s + "_m_custom_excel_in_err")
        redirect_to m_custom_excel_url, alert: "Excelの取込に失敗しました。　" + row_hkn.to_s + "行目でエラーが発生しました。"
      end
      
    else
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
      
      @m_customs = MCustom.joins("left join m_customs admin on admin.cust_kbn='#{G_CUST_KBN_ADMIN}' and admin.cust_code=m_customs.admin_code").joins("left join (select cust_kbn, cust_code, max(route_code) as route_code from m_route_points group by cust_kbn, cust_code) mrp on mrp.cust_kbn=m_customs.cust_kbn and mrp.cust_code=m_customs.cust_code").joins("left join m_routes mr on mr.route_code=mrp.route_code").joins("left join m_combos c1 on c1.class_1='#{G_USE_CONTENT_CLASS_1}' and c1.class_2=0 and c1.class_code=m_customs.use_content").where("#{strwhere}").select("m_customs.*, admin.cust_name as admin_name, mrp.route_code, mr.route_name, c1.class_name as use_content_name").order("m_customs.cust_code")
      
      pkg = Axlsx::Package.new
      pkg.workbook do |wb|
        wb.add_worksheet(:name => 'ステーション') do |ws|   # シート名の指定は省略可
          # ヘッダ行
          header_style = ws.styles.add_style :bg_color => "C0C0C0", :border => {:style => :thin, :color => "FF333333"}
          ws.add_row(['ｽﾃｰｼｮﾝｺｰﾄﾞ', 'ステーション名','住所','ｱﾊﾟｰﾄ･ﾏﾝｼｮﾝ･ﾋﾞﾙ名','利用内容','利用世帯数','利用人数','備考','管理者名','収集区','申請区分'], :style=>header_style)
          # 横幅
          ws.column_widths(11, 50, 40, 40, 20, 5, 5, 50, 40, 40, 10)
          detail_style = ws.styles.add_style :border => {:style => :thin, :color => "FF333333"}
          @m_customs.each do |m_custom|
            ws.add_row([m_custom.cust_code, m_custom.cust_name, m_custom.addr_1, m_custom.addr_2, m_custom.use_content_name, m_custom.setai_count, m_custom.use_count, m_custom.memo, m_custom.admin_name, m_custom.route_name, '変更'], :types => [:string, :string, :string, :string, :string, :integer, :integer, :string, :string, :string, :string], :style=>detail_style)
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
end
