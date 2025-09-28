class IppanUnpanReport001Controller < ApplicationController
  before_action :authenticate_user!

  # GET /ippan_unpan_report001
  def index
    @month = Time.now.months_ago(1).try(:strftime, "%Y%m")
  end

  # POST /ippan_unpan_report001
  def excel
    
    # Excel書き出し
    month_from = (params[:month][:query].to_s + "01").to_date
    month_to = (params[:month][:query].to_s + "01").to_date.ago(-1.month).ago(1.day)
    month_next = (params[:month][:query].to_s + "01").to_date.ago(-1.month)
    
    @t_collect_details = TCollectDetail.joins("inner join t_collect_lists tcl on tcl.out_timing=t_collect_details.out_timing and tcl.car_code=t_collect_details.car_code and tcl.spot_no=t_collect_details.spot_no")
    @t_collect_details = @t_collect_details.joins("inner join t_carruns tc on tc.out_timing=tcl.out_timing and tc.car_code=tcl.car_code")
    @t_collect_details = @t_collect_details.joins("left join m_cars car on car.car_code=tc.car_code")
    @t_collect_details = @t_collect_details.joins("left join m_customs itaku on itaku.cust_kbn='#{G_CUST_KBN_GYOSHA}' and itaku.cust_code=car.itaku_code")
    @t_collect_details = @t_collect_details.joins("left join m_combos item on item.class_1='#{G_ITEM_CLASS_1}' and item.class_code=t_collect_details.item_kbn")
    @t_collect_details = @t_collect_details.where("tcl.cust_kbn=? and t_collect_details.out_timing>=? and t_collect_details.out_timing<?", G_CUST_KBN_UNLOAD, month_from, month_next)
    
    @item_headers = @t_collect_details.select("t_collect_details.item_kbn, max(item.class_name) as item_name")
    @item_headers = @item_headers.group("t_collect_details.item_kbn")
    @item_headers = @item_headers.order("t_collect_details.item_kbn")
    
    pkg = Axlsx::Package.new
    
    pkg.workbook do |wb|
      itaku_code_hkn = "-1"
      itaku_count = 0
      
      @item_headers.each do |item_header|

        item_kbn_hkn = item_header.item_kbn.to_s
        itaku_count = 0
        wb.add_worksheet(:name => item_header.item_kbn.to_s + item_header.item_name.to_s) do |ws|   # シート名の指定は省略可
          # パターン
          excel_pattern(ws, month_from, month_to, item_header)
          
          # 横幅
          @arrWidth =  [3,4,4.5,10.5,4.5,10.5,4.5,10.5,4.5,10.5,4.5,10.5]
          ws.column_widths *@arrWidth

          @item_meisais = @t_collect_details.where("t_collect_details.item_kbn=?", item_header.item_kbn.to_s)
          @item_meisais = @item_meisais.select("Date(t_collect_details.out_timing) as out_date, t_collect_details.item_kbn, max(item.class_name) as item_name, car.itaku_code, max(itaku.cust_name) as itaku_name, sum(t_collect_details.item_weight) as item_weight")
          @item_meisais = @item_meisais.group("t_collect_details.item_kbn, car.itaku_code, Date(t_collect_details.out_timing)")
          @item_meisais = @item_meisais.order("t_collect_details.item_kbn, car.itaku_code, Date(t_collect_details.out_timing)")
          
          # 値代入
          @item_meisais.each do |item_meisai|
            if itaku_code_hkn.to_s!=item_meisai.itaku_code.to_s
              itaku_code_hkn = item_meisai.itaku_code.to_s
              itaku_count = itaku_count + 1
              ws.rows[11].cells[(itaku_count*2)].value = item_meisai.itaku_name.to_s
            end
            ws.rows[12+item_meisai.out_date.try(:strftime, "%d").to_i].cells[(itaku_count*2)+1].value = item_meisai.item_weight
          end
          
        end
      end
    end

    if (/MSIE/ =~ request.user_agent) || (/Trident/ =~ request.user_agent) || (/Edge/ =~ request.user_agent)
      send_data(pkg.to_stream.read, 
        :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        :filename => "一般廃棄物収集運搬業務実績報告書.xlsx".encode('Shift_JIS'))
    else
      send_data(pkg.to_stream.read, 
        :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        :filename => "一般廃棄物収集運搬業務実績報告書.xlsx")
    end
  end

  private
  
  def excel_pattern(ws, month_from, month_to, item_header)
    
    # 年度設定
    year_from = month_from
    if month_from.strftime("%m").to_i <= 3
      year_from = year_from.years_ago(1)
    end
    # ヘッダ行
    header_style = ws.styles.add_style :border => { :style => :thin, :color => "00" }, :alignment => {:horizontal => :center}
    border_style = ws.styles.add_style :border => { :style => :thin, :color => "00" }
    border_style_right = ws.styles.add_style :border => { :style => :thin, :color => "00" }, :alignment => {:horizontal => :right}
    border_style_center = ws.styles.add_style :border => { :style => :thin, :color => "00" }, :alignment => {:horizontal => :center}
    footer_style = ws.styles.add_style :border => { :style => :thin, :color => "00"}
    footer_style_center = ws.styles.add_style :border => { :style => :thin, :color => "00"}, :alignment => {:horizontal => :center}

    ws.add_row(['報告様式３'])
    ws.add_row(['江 別 市 一 般 廃 棄 物 収 集 運 搬 業 務 実 績 報 告 書'])
    ws.add_row()
    ws.add_row(['',year_from,'','','','','','（' + item_header.item_name.to_s + '）','','','',''])
    ws.add_row(['',month_from])
    ws.add_row()
    ws.add_row(['次のとおり報告いたします。'])
    ws.add_row()
    ws.add_row(['','','','','','','','事業所　　江別リサイクル事業協同組合'])
    ws.add_row(['','','','','','','','代表者　　代表理事　　斎　木　良　一'])
    ws.add_row()
    ws.add_row(['業者名','','','','','','','','','','計',''], :style => [header_style,header_style,header_style,header_style,header_style,header_style,header_style,header_style,header_style,header_style,header_style,header_style])
    ws.add_row(['日','曜日','回数','搬入量(Kg)','回数','搬入量(Kg)','回数','搬入量(Kg)','回数','搬入量(Kg)','回数','搬入量(Kg)'], :style => [header_style,header_style,header_style,header_style,header_style,header_style,header_style,header_style,header_style,header_style,header_style,header_style])

    # 明細行
    for num in 0..30 do
      arrMeisai = []
      arrMeisai.push(nil)
      arrMeisai.push(nil)
      for num2 in 2..9 do
        arrMeisai.push(0)
      end
      arrMeisai.push("="+Axlsx::cell_r(2,num+13) + '+' + Axlsx::cell_r(4,num+13) + '+' + Axlsx::cell_r(6,num+13) + '+' + Axlsx::cell_r(8,num+13))
      arrMeisai.push("="+Axlsx::cell_r(3,num+13) + '+' + Axlsx::cell_r(5,num+13) + '+' + Axlsx::cell_r(7,num+13) + '+' + Axlsx::cell_r(9,num+13))
      
      ws.add_row(arrMeisai.to_a, :style => [border_style_right,border_style_center,border_style_right,border_style_right,border_style_right,border_style_right,border_style_right,border_style_right,border_style_right,border_style_right,border_style_right,border_style_right])
    end

    rowCount = 12
    (month_from.to_date..month_to.to_date).each do |date|
      rowCount = rowCount + 1
      ws.rows[rowCount].cells[0].value = date.strftime("%d").to_i
      ws.rows[rowCount].cells[1].value = date.strftime("#{%w(日 月 火 水 木 金 土)[date.wday]}")
      for num in 2..9 do
        ws.rows[rowCount].cells[num].value = nil
      end
    end
    
    # 合計行
    arrFooter = []
    arrFooter.push("計")
    arrFooter.push("")
    for num in 2..11 do
      arrFooter.push("=SUM("+Axlsx::cell_r(num,13) + ':' + Axlsx::cell_r(num,43)+")")
    end
    ws.add_row(arrFooter.to_a, :style => [footer_style_center,footer_style,footer_style,footer_style,footer_style,footer_style,footer_style,footer_style,footer_style,footer_style,footer_style,footer_style])
    
    # 書式
    ws.merge_cells Axlsx::cell_r(0,0) + ':' + Axlsx::cell_r(11,0) #A1:L1
    ws.merge_cells Axlsx::cell_r(0,1) + ':' + Axlsx::cell_r(11,1) #A2:L2
    ws.merge_cells Axlsx::cell_r(1,3) + ':' + Axlsx::cell_r(3,3) #B4:D4
    ws.merge_cells Axlsx::cell_r(7,3) + ':' + Axlsx::cell_r(11,3) #H4:L4
    ws.merge_cells Axlsx::cell_r(1,4) + ':' + Axlsx::cell_r(3,4) #B5:D5
    ws.merge_cells Axlsx::cell_r(0,11) + ':' + Axlsx::cell_r(1,11) #A12:B12
    ws.merge_cells Axlsx::cell_r(2,11) + ':' + Axlsx::cell_r(3,11) #C12:D12
    ws.merge_cells Axlsx::cell_r(4,11) + ':' + Axlsx::cell_r(5,11) #E12:F12
    ws.merge_cells Axlsx::cell_r(6,11) + ':' + Axlsx::cell_r(7,11) #G12:H12
    ws.merge_cells Axlsx::cell_r(8,11) + ':' + Axlsx::cell_r(9,11) #I12:J12
    ws.merge_cells Axlsx::cell_r(10,11) + ':' + Axlsx::cell_r(11,11) #K12:L12
    ws.merge_cells Axlsx::cell_r(0,44) + ':' + Axlsx::cell_r(1,44) #A45:B452
    
    ws.rows[0].cells[0].style = ws.styles.add_style :sz => 11, :alignment => {:horizontal => :right}
    ws.rows[1].cells[0].style = ws.styles.add_style :sz => 11, :b => true, :alignment => {:horizontal => :center}
    ws.rows[3].cells[1].style = ws.styles.add_style :sz => 11, :u => :true, :format_code => "[$-411]ggge年度", :alignment => {:horizontal => :left}
    ws.rows[3].cells[7].style = ws.styles.add_style :sz => 11, :alignment => {:horizontal => :right}
    ws.rows[4].cells[1].style = ws.styles.add_style :sz => 11, :format_code => "[$-411]ggge年m月分", :alignment => {:horizontal => :left}
  end
end
