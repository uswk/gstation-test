class CollectUncompController < ApplicationController

  before_action :authenticate_user!
  before_action :set_route, :only => [:index]
  before_action :set_itaku, :only => [:index]
  before_action :set_where, :only => [:index, :excel]
  
  # GET /collect_uncomp
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
  # POST /uncollect
  def excel
    
    # Excel書き出し
    pkg = Axlsx::Package.new
    pkg.workbook do |wb|
      wb.add_worksheet(:name => '収集未完了一覧') do |ws|   # シート名の指定は省略可
        # ヘッダ行
        header_style = ws.styles.add_style :bg_color => "C0C0C0", :border => {:style => :thin, :color => "FF333333"}
        ws.add_row(['委託会社ｺｰﾄﾞ', '委託会社名', '収集区ｺｰﾄﾞ', '収集区名','車両ｺｰﾄﾞ','車両','出庫日時','帰庫日時','ｽﾃｰｼｮﾝｺｰﾄﾞ','ステーション名'], :style=>header_style)
        # 横幅
        ws.column_widths(10, 20, 10, 20, 10, 20, 10, 10, 10, 30)
        detail_style = ws.styles.add_style :border => {:style => :thin, :color => "FF333333"}
        @t_collect_lists.each do |t_collect_list|
          ws.add_row([t_collect_list.itaku_code, t_collect_list.itaku_name, t_collect_list.route_code, t_collect_list.route_name, t_collect_list.car_code, t_collect_list.car_reg_code, t_collect_list.out_timing.try(:strftime, "%Y/%m/%d %H:%M:%S"), t_collect_list.in_timing.try(:strftime, "%Y/%m/%d %H:%M:%S"), t_collect_list.cust_code, t_collect_list.cust_name], :types => [:string, :string, :string, :string, :string, :string, :string, :string, :string, :string], :style=>detail_style)
        end
      end
    end
    if (/MSIE/ =~ request.user_agent) || (/Trident/ =~ request.user_agent) || (/Edge/ =~ request.user_agent)
      send_data(pkg.to_stream.read, 
        :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        :filename => "収集未完了一覧.xlsx".encode('Shift_JIS'))
    else
      send_data(pkg.to_stream.read, 
        :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        :filename => "収集未完了一覧.xlsx")
    end
    api_log_hists(203, 5, "")
  end
  
  private
    def set_route
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
    
    def set_where
      if not params[:excel_date].blank?
        @routecode = params[:excel_route_code].blank? ? "" : params[:excel_route_code]
        @itakucode = params[:excel_itaku_code].blank? ? "" : params[:excel_itaku_code]
        @outdate = params[:excel_date].blank? ? Date.today.try(:strftime, "%Y/%m/%d") : params[:excel_date]
      else
        @routecode = params[:search].blank? ? "" : params[:search][:route]
        @itakucode = params[:search].blank? ? "" : params[:search][:itaku]
        @outdate = params[:search].blank? ? Date.today.try(:strftime, "%Y/%m/%d") : params[:search][:date]
      end
      @outdate_to = DateTime.strptime(@outdate, "%Y/%m/%d").tomorrow
      @strwhere = "tcl.finish_timing is null and comp.cust_code is null"
      if @outdate != ""
        @strwhere = @strwhere + " AND t_carruns.out_timing>='#{@outdate}'"
        @strwhere = @strwhere + " AND t_carruns.out_timing<'#{@outdate_to}'"
      end
      if @routecode != ""
        @strwhere = @strwhere + " AND t_carruns.route_code = '#{@routecode}'"
      end
      if not current_user.itaku_code.blank?
        @strwhere = @strwhere + " AND m_cars.itaku_code='#{current_user.itaku_code}'"
      else
        if @itakucode != ""
          @strwhere = @strwhere + " AND m_cars.itaku_code='#{@itakucode}'"
        end
      end
      @t_collect_lists = TCarrun.joins("inner join t_collect_lists tcl on tcl.out_timing=t_carruns.out_timing and tcl.car_code=t_carruns.car_code")
      @t_collect_lists = @t_collect_lists.joins("left join m_cars ON m_cars.car_code=t_carruns.car_code")
      @t_collect_lists = @t_collect_lists.joins("left join m_routes ON m_routes.route_code=t_carruns.route_code")
      @t_collect_lists = @t_collect_lists.joins("left join m_customs itaku ON itaku.cust_kbn='#{G_CUST_KBN_GYOSHA}' and itaku.cust_code=m_cars.itaku_code")
      @t_collect_lists = @t_collect_lists.joins("left join (select tc.route_code, tcl.cust_kbn, tcl.cust_code from t_collect_lists tcl inner join t_carruns tc on tc.out_timing=tcl.out_timing and tc.car_code=tcl.car_code where tcl.out_timing>='#{@outdate}' and tcl.out_timing<'#{@outdate_to}' and tcl.finish_timing is not null group by tc.route_code, tcl.cust_kbn, tcl.cust_code) comp on comp.route_code=t_carruns.route_code and comp.cust_kbn=tcl.cust_kbn and comp.cust_code=tcl.cust_code")
      @t_collect_lists = @t_collect_lists.select("t_carruns.*, tcl.cust_kbn, tcl.cust_code, tcl.cust_name, m_cars.car_reg_code, m_routes.route_name, itaku.cust_code as itaku_code, itaku.cust_name as itaku_name")
      @t_collect_lists = @t_collect_lists.where("#{@strwhere}")
      @t_collect_lists = @t_collect_lists.order("tcl.cust_kbn, tcl.cust_code, t_carruns.out_timing, t_carruns.id")
    end
end
