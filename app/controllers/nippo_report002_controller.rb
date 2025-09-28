class NippoReport002Controller < ApplicationController
  before_action :authenticate_user!
    before_action :set_itaku, :only => [:index]

  # GET /nippo_report002
  def index
  end

  # POST /nippo_report002
  def excel
    @now_date = params[:search][:date_from].to_date
    @tom_date = params[:search][:date_to].to_date.tomorrow.strftime("%Y/%m/%d")
    @itaku_code = params[:search][:itaku]
    @strwhere = ""
    if not @itaku_code.blank?
      @strwhere = @strwhere + " and car.itaku_code='#{@itaku_code}'"
    end
    
    if not current_user.itaku_code.blank?
      @strwhere = @strwhere + " and car.itaku_code='#{current_user.itaku_code}'"
    else
      if not @itaku_code.blank?
        @strwhere = @strwhere + " and car.itaku_code='#{@itaku_code}'"
      end
    end
    
    # Excel書き出し
    @t_collect_details = TCarrun.joins("left join m_cars car on car.car_code=t_carruns.car_code")
    @t_collect_details = @t_collect_details.where("t_carruns.out_timing >= ? and t_carruns.out_timing < ?" + @strwhere, @now_date, @tom_date)
    @t_collect_details = @t_collect_details.select("t_carruns.car_code, car.car_reg_code, Date(t_carruns.out_timing) as out_date, sum(case when (t_carruns.mater_in > 0 AND t_carruns.mater_in >= t_carruns.mater_out AND (t_carruns.mater_in - t_carruns.mater_out) <= 1000) then ifnull(t_carruns.mater_in,0)-ifnull(t_carruns.mater_out,0) else 0 end) distance").group("t_carruns.car_code, Date(t_carruns.out_timing)").order("t_carruns.car_code, Date(t_carruns.out_timing)")

    @iCount = 0
    @fCount = 0
    @carCode = ""
    if not @t_collect_details.blank?
      @carCode = @t_collect_details[0].car_code.to_s
    end
    @strselect = ""
    
      pkg = Axlsx::Package.new
    
      pkg.workbook do |wb|
        wb.add_worksheet(:name => '車両別日別走行距離一覧') do |ws|
          # スタイル
          header_center_style = ws.styles.add_style :sz => 9, :bg_color => "C0C0C0", :border => { :style => :thin, :color => "00" }, :alignment => {:horizontal => :center}
          header_style = ws.styles.add_style :sz => 9, :bg_color => "C0C0C0", :border => { :style => :thin, :color => "00" }
          detail_style = ws.styles.add_style :sz => 9, :border => { :style => :thin, :color => "00" }, :alignment => {:vertical => :center, :wrap_text => true}
          detail_mi_style = ws.styles.add_style :sz => 9, :bg_color => "FF00FF", :border => { :style => :thin, :color => "00" }, :alignment => {:vertical => :center, :wrap_text => true}
        
          # 見出し
          arrHeader = []
          arrHeaderStyle = []
          arrDate = []
          arrHeader.push('車両')
          arrHeader.push('日付')
          arrHeader.push('走行距離(km)')
          arrHeaderStyle.push(header_center_style)
          arrHeaderStyle.push(header_center_style)
          arrHeaderStyle.push(header_center_style)
          ws.add_row(["車両別日別走行距離一覧（" + params[:search][:date_from].to_s + "～" + params[:search][:date_to].to_s + "）"])
          ws.add_row(arrHeader.to_a, :style=>arrHeaderStyle.to_a)
          @t_collect_details.each do |t_collect_detail|
            if @carCode!=t_collect_detail.car_code.to_s
              arrFooter = []
              arrFooterStyle = []
              arrFooter.push('小計')
              arrFooter.push('')
              arrFooter.push("=SUBTOTAL(9,"+Axlsx::cell_r(2,@fCount+2) + ':' + Axlsx::cell_r(2,@iCount+1)+")")
              arrFooterStyle.push(header_center_style)
              arrFooterStyle.push(header_center_style)
              arrFooterStyle.push(header_style)
              ws.add_row(arrFooter.to_a, :style=>arrFooterStyle.to_a)

              @fCount = @iCount + 1
              @iCount = @iCount + 1
              @carCode = t_collect_detail.car_code.to_s
            end

            arrMeisai = []
            arrStyle = []
            arrMeisai.push(t_collect_detail.car_reg_code.to_s)
            arrMeisai.push(t_collect_detail.out_date.strftime("%Y/%m/%d").to_s)
            arrMeisai.push(t_collect_detail.distance.to_s)
            arrStyle.push(detail_style)
            arrStyle.push(detail_style)
            arrStyle.push(detail_style)
            ws.add_row(arrMeisai.to_a, :types => [:string, :string, :integer], :style=>arrStyle.to_a)
            @iCount = @iCount + 1
          end
          
          arrFooter = []
          arrFooterStyle = []
          arrFooter.push('小計')
          arrFooter.push('')
          arrFooter.push("=SUBTOTAL(9,"+Axlsx::cell_r(2,@fCount+2) + ':' + Axlsx::cell_r(2,@iCount+1)+")")
          arrFooterStyle.push(header_center_style)
          arrFooterStyle.push(header_center_style)
          arrFooterStyle.push(header_style)
          ws.add_row(arrFooter.to_a, :style=>arrFooterStyle.to_a)

          @fCount = @iCount + 1
          @iCount = @iCount + 1
          
          arrFooter = []
          arrFooterStyle = []
          arrFooter.push('合計')
          arrFooter.push('')
          arrFooter.push("=SUBTOTAL(9,"+Axlsx::cell_r(2,2) + ':' + Axlsx::cell_r(2,@iCount+1)+")")
          arrFooterStyle.push(header_center_style)
          arrFooterStyle.push(header_center_style)
          arrFooterStyle.push(header_style)
          ws.add_row(arrFooter.to_a, :style=>arrFooterStyle.to_a)

          # 横幅
          @arrWidth =  [15,15,12]
          ws.column_widths *@arrWidth
          
          ws.auto_filter = Axlsx::cell_r(0,1) + ":" + Axlsx::cell_r(2,1)
        end
      end

      if (/MSIE/ =~ request.user_agent) || (/Trident/ =~ request.user_agent) || (/Edge/ =~ request.user_agent)
        send_data(pkg.to_stream.read, 
          :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          :filename => "車両別日別走行距離一覧.xlsx".encode('Shift_JIS'))
      else
        send_data(pkg.to_stream.read, 
          :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          :filename => "車両別日別走行距離一覧.xlsx")
      end
  end

  private
    def set_itaku
      #委託会社プルダウン用
      @itaku_codes = MCustom.where("cust_kbn=5 and delete_flg=0").order("cust_code asc").map{|i| [i.cust_code.to_s + ':' + i.cust_name.to_s, i.cust_code] }
    end
end
