class NippoReport001Controller < ApplicationController
  before_action :authenticate_user!
    before_action :set_route, :only => [:index]
    before_action :set_itaku, :only => [:index]

  # GET /nippo_report001
  def index
  end

  # POST /nippo_report001
  def excel
    @now_date = params[:search][:date_from].to_date
    @tom_date = params[:search][:date_to].to_date.tomorrow.strftime("%Y/%m/%d")
    @route_code = params[:search][:route]
    @itaku_code = params[:search][:itaku]
    @strwhere = ""
    if not @route_code.blank?
      @strwhere = @strwhere + " and t_carruns.route_code='#{@route_code}'"
    end
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
    @t_collect_headers = TCarrun.joins("left join m_cars car on car.car_code=t_carruns.car_code")
    @t_collect_headers = @t_collect_headers.where("t_carruns.out_timing >= ? and t_carruns.out_timing < ?" + @strwhere, @now_date, @tom_date)
    @t_collect_headers = @t_collect_headers.select("Date(t_carruns.out_timing) as out_date").group("Date(t_carruns.out_timing)").order("Date(t_carruns.out_timing)")

    @t_collect_lists = TCollectList.joins("INNER JOIN t_carruns on t_carruns.out_timing=t_collect_lists.out_timing and t_carruns.car_code=t_collect_lists.car_code")
    @t_collect_lists = @t_collect_lists.joins("inner join m_cars car on car.car_code=t_carruns.car_code")
    @t_collect_lists = @t_collect_lists.joins("left join m_customs itaku on itaku.cust_kbn='#{G_CUST_KBN_GYOSHA}' and itaku.cust_code=car.itaku_code")
    @t_collect_lists = @t_collect_lists.joins("left join m_routes mr on mr.route_code=t_carruns.route_code")
    @t_collect_lists = @t_collect_lists.joins("left join m_customs mc on mc.cust_kbn=t_collect_lists.cust_kbn and mc.cust_code=t_collect_lists.cust_code")
    @t_collect_lists = @t_collect_lists.joins("left join m_route_points mrp on mrp.route_code=t_carruns.route_code and mrp.cust_kbn=t_collect_lists.cust_kbn and mrp.cust_code=t_collect_lists.cust_code")
    @iCount = 0
    @strselect = ""
    @t_collect_headers.each do |t_collect_header|
      @iCount = @iCount + 1
      @strselect = @strselect + ", DATE_FORMAT(max(tcl" + t_collect_header.out_date.strftime("%Y%m%d").to_s + ".finish_timing),'%k:%i') as '" + t_collect_header.out_date.strftime("%Y%m%d").to_s + "'"
      @strselect = @strselect + ", max(tcl" + t_collect_header.out_date.strftime("%Y%m%d").to_s + ".mikaishu_count) as 'mi_" + t_collect_header.out_date.strftime("%Y%m%d").to_s + "'"
      @t_collect_lists = @t_collect_lists.joins("left join (select Date(tcl.out_timing) as out_date, tcl.cust_kbn, tcl.cust_code, max(tcl.finish_timing) as finish_timing, max(tcl.mikaishu_count) as mikaishu_count, tc.route_code, car.itaku_code from t_collect_lists tcl inner join t_carruns tc on tc.out_timing=tcl.out_timing and tc.car_code=tcl.car_code inner join m_cars car on car.car_code=tc.car_code where tcl.out_timing>='#{t_collect_header.out_date}' and tcl.out_timing<'#{t_collect_header.out_date.to_date.since(1.days).strftime("%Y-%m-%d")}' group by Date(tcl.out_timing), tcl.cust_kbn, tcl.cust_code, tc.route_code, car.itaku_code) tcl" + t_collect_header.out_date.strftime("%Y%m%d").to_s + " on tcl" + t_collect_header.out_date.strftime("%Y%m%d").to_s + ".cust_kbn=t_collect_lists.cust_kbn and tcl" + t_collect_header.out_date.strftime("%Y%m%d").to_s + ".cust_code=t_collect_lists.cust_code and tcl" + t_collect_header.out_date.strftime("%Y%m%d").to_s + ".route_code=t_carruns.route_code and tcl" + t_collect_header.out_date.strftime("%Y%m%d").to_s + ".itaku_code=car.itaku_code and tcl" + t_collect_header.out_date.strftime("%Y%m%d").to_s + ".out_date=Date(t_collect_lists.out_timing)")
    end
    @t_collect_lists = @t_collect_lists.where("t_collect_lists.cust_kbn='#{G_CUST_KBN_STATION}' and t_collect_lists.cust_code<>'*' and t_collect_lists.out_timing >= ? and t_collect_lists.out_timing < ?" + @strwhere, @now_date, @tom_date)
    @t_collect_lists = @t_collect_lists.select("t_collect_lists.cust_kbn, t_collect_lists.cust_code, max(t_collect_lists.finish_timing) as finish_timing, max(t_collect_lists.spot_no) as spot_no, t_collect_lists.cust_name, mc.addr_1, mc.addr_2, mc.memo, itaku.cust_name as itaku_name, mr.route_name, mrp.tree_no, case when mrp.cust_code is null then 0 else 1 end as cust_flg " + @strselect.to_s)
    @t_collect_lists = @t_collect_lists.group("car.itaku_code, t_carruns.route_code, mrp.tree_no, t_collect_lists.cust_kbn, t_collect_lists.cust_code")
    @t_collect_lists = @t_collect_lists.order(Arel.sql("car.itaku_code, t_carruns.route_code, mrp.tree_no is null ASC, mrp.tree_no, t_collect_lists.cust_kbn, t_collect_lists.cust_code"))
    
    if @iCount>50
      redirect_to nippo_report001_url.to_s, notice: '表示する日付が多すぎるため処理することができませんでした。期間を見直してください。※横に表示できる日付は最大50日分までです。'
    else
      pkg = Axlsx::Package.new
    
      pkg.workbook do |wb|
        wb.add_worksheet(:name => 'ステーション別日報一覧') do |ws|
          # スタイル
          header_center_style = ws.styles.add_style :sz => 9, :bg_color => "C0C0C0", :border => { :style => :thin, :color => "00" }, :alignment => {:horizontal => :center}
          header_style = ws.styles.add_style :sz => 9, :bg_color => "C0C0C0", :border => { :style => :thin, :color => "00" }
          detail_style = ws.styles.add_style :sz => 9, :border => { :style => :thin, :color => "00" }, :alignment => {:vertical => :center, :wrap_text => true}
          detail_mi_style = ws.styles.add_style :sz => 9, :bg_color => "FF00FF", :border => { :style => :thin, :color => "00" }, :alignment => {:vertical => :center, :wrap_text => true}
        
          # 見出し
          arrHeader = []
          arrHeaderStyle = []
          arrDate = []
          arrHeader.push('委託会社')
          arrHeader.push('収集区')
          arrHeader.push('SEQ')
          arrHeader.push('ステーション名')
          arrHeader.push('住所')
          arrHeader.push('備考')
          arrHeaderStyle.push(header_center_style)
          arrHeaderStyle.push(header_center_style)
          arrHeaderStyle.push(header_center_style)
          arrHeaderStyle.push(header_center_style)
          arrHeaderStyle.push(header_center_style)
          arrHeaderStyle.push(header_center_style)
          @t_collect_headers.each do |t_collect_header|
            arrHeader.push(t_collect_header.out_date.strftime("%m/%d").to_s)
            arrDate.push(t_collect_header.out_date.strftime("%Y-%m-%d").to_s)
            arrHeaderStyle.push(header_style)
          end
          ws.add_row(["ステーション別日報一覧（" + params[:search][:date_from].to_s + "～" + params[:search][:date_to].to_s + "）"])
          ws.add_row(arrHeader.to_a, :style=>arrHeaderStyle.to_a)

          # 明細
          @t_collect_lists.each do |t_collect_list|
            arrMeisai = []
            arrStyle = []
            arrMeisai.push(t_collect_list.itaku_name.to_s)
            arrMeisai.push(t_collect_list.route_name.to_s)
            arrMeisai.push(t_collect_list.tree_no)
            arrMeisai.push(t_collect_list.cust_name.to_s)
            arrMeisai.push(t_collect_list.addr_1.to_s + t_collect_list.addr_2.to_s)
            arrMeisai.push(t_collect_list.memo.to_s)
            
            arrStyle.push(detail_style)
            arrStyle.push(detail_style)
            arrStyle.push(detail_style)
            arrStyle.push(detail_style)
            arrStyle.push(detail_style)
            arrStyle.push(detail_style)
            @finish_flg = 0
            for num in 1..arrDate.length
              if not t_collect_list[arrDate[num-1].to_date.strftime("%Y%m%d").to_s].blank?
                @finish_flg = 1
              end
              arrMeisai.push(t_collect_list[arrDate[num-1].to_date.strftime("%Y%m%d").to_s])
              if t_collect_list["mi_" + arrDate[num-1].to_date.strftime("%Y%m%d").to_s].blank?
                arrStyle.push(detail_style)
              else
                arrStyle.push(detail_mi_style)
              end
            end
            if t_collect_list.cust_flg.to_s=="1" || @finish_flg==1
              ws.add_row(arrMeisai.to_a, :types => [:string, :string, :integer, :string, :string, :string], :style=>arrStyle.to_a)
            end
          end

          # 横幅
          @arrWidth =  [15,25,5,15,40,40]
          ws.column_widths *@arrWidth
          
          #ウィンドウ固定
          ws.sheet_view.pane do |pane|
            pane.top_left_cell = "E3"
            pane.state = :frozen_split
            pane.y_split = 2
            pane.x_split = 4
            pane.active_pane = :bottom_left
          end
          
          ws.auto_filter = Axlsx::cell_r(0,1) + ":" + Axlsx::cell_r(5+@iCount,1)
        end
      end

      if (/MSIE/ =~ request.user_agent) || (/Trident/ =~ request.user_agent) || (/Edge/ =~ request.user_agent)
        send_data(pkg.to_stream.read, 
          :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          :filename => "ステーション別日報一覧.xlsx".encode('Shift_JIS'))
      else
        send_data(pkg.to_stream.read, 
          :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          :filename => "ステーション別日報一覧.xlsx")
      end

    end
  end

  private
    def set_route
      #収集区プルダウン用
      if current_user.itaku_code.blank?
        routewhere = "m_routes.delete_flg = 0"
      else
        routewhere = "m_routes.delete_flg = 0 and mrr.itaku_code = '#{current_user.itaku_code}'"
      end
      @route_codes = MRoute.joins("left join m_route_rundates mrr on mrr.route_code=m_routes.route_code")
      @route_codes = @route_codes.where("#{routewhere}").group("m_routes.route_code, m_routes.route_name").order("m_routes.route_code asc").map{|i| [i.route_code.to_s + ':' + i.route_name.to_s, i.route_code] }
    end
    
    def set_itaku
      #委託会社プルダウン用
      @itaku_codes = MCustom.where("cust_kbn=5 and delete_flg=0").order("cust_code asc").map{|i| [i.cust_code.to_s + ':' + i.cust_name.to_s, i.cust_code] }
    end
end
