class UncollectController < ApplicationController

  before_action :authenticate_user!
  before_action :set_route, :only => [:index]
  before_action :set_itaku, :only => [:index]
  before_action :set_where, :only => [:index, :excel]
  before_action :set_search_params, only: [:destroy]
  
  # GET /uncollect
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
  # GET /uncollect/1
  def show
    @t_carrun_memos = TCarrunMemo.joins("left join t_carruns tc on tc.id=t_carrun_memos.carrun_id")
    @t_carrun_memos = @t_carrun_memos.joins("left join m_routes mr on mr.route_code=tc.route_code")
    @t_carrun_memos = @t_carrun_memos.joins("left join m_cars mc on mc.car_code=tc.car_code")
    @t_carrun_memos = @t_carrun_memos.where("t_carrun_memos.carrun_id=? and ((t_carrun_memos.cust_code='*' and t_carrun_memos.finish_timing=?) or (t_carrun_memos.cust_code<>'*' and t_carrun_memos.cust_kbn=? and t_carrun_memos.cust_code=?))", params[:id], params[:finish_timing], params[:cust_kbn], params[:cust_code])
    @t_carrun_memos = @t_carrun_memos.select("t_carrun_memos.*, tc.out_timing, tc.in_timing, tc.input_flg, mr.route_name, mc.car_reg_code")
    @t_carrun_memos = @t_carrun_memos.order("t_carrun_memos.id")

    if not params[:collect_flg].blank?
      @header_no_dsp = 1
    end
    @collect_flg = params[:collect_flg].to_s
    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
  # POST /uncollect
  def excel
    
    # Excel書き出し
    pkg = Axlsx::Package.new
    pkg.workbook do |wb|
      wb.add_worksheet(:name => '未回収一覧') do |ws|   # シート名の指定は省略可
        # ヘッダ行
        header_style = ws.styles.add_style :bg_color => "C0C0C0", :border => {:style => :thin, :color => "FF333333"}
        ws.add_row(['委託会社ｺｰﾄﾞ', '委託会社名','収集区ｺｰﾄﾞ', '収集区名','車両ｺｰﾄﾞ','車両','出庫日時','帰庫日時','ｽﾃｰｼｮﾝｺｰﾄﾞ','ステーション名','収集時間','未回収理由','未回収数'], :style=>header_style)
        # 横幅
        ws.column_widths(10, 20, 10, 20, 10, 20, 10, 10, 10, 30, 10, 12, 10, 10)
        detail_style = ws.styles.add_style :border => {:style => :thin, :color => "FF333333"}
        @t_collect_lists.each do |t_collect_list|
          ws.add_row([t_collect_list.itaku_code, t_collect_list.itaku_name, t_collect_list.route_code, t_collect_list.route_name, t_collect_list.car_code, t_collect_list.car_reg_code, t_collect_list.out_timing.try(:strftime, "%Y/%m/%d %H:%M:%S"), t_collect_list.in_timing.try(:strftime, "%Y/%m/%d %H:%M:%S"), t_collect_list.cust_code, t_collect_list.cust_name, t_collect_list.finish_timing.try(:strftime, "%H:%M:%S"), t_collect_list.mikaishu_name, t_collect_list.mikaishu_count], :types => [:string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :integer], :style=>detail_style)
        end
      end
    end
    if (/MSIE/ =~ request.user_agent) || (/Trident/ =~ request.user_agent) || (/Edge/ =~ request.user_agent)
      send_data(pkg.to_stream.read, 
        :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        :filename => "未回収一覧.xlsx".encode('Shift_JIS'))
    else
      send_data(pkg.to_stream.read, 
        :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        :filename => "未回収一覧.xlsx")
    end
    api_log_hists(204, 5, "")
  end
  
  # DELETE /uncollect/1
  def destroy
    @t_carrun_memo = TCarrunMemo.find(params[:id])
    @t_carrun_memo.destroy
    respond_to do |format|
      api_log_hists(204, 3,"メモ・写真")
      format.html { redirect_to uncollect_url.to_s+@search_params.to_s, alert: "削除作業が完了しました。"}
    end
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

      if not params[:excel_date_from].blank?
        @routecode = params[:excel_route_code].blank? ? "" : params[:excel_route_code]
        @itakucode = params[:excel_itaku_code].blank? ? "" : params[:excel_itaku_code]
        @custcode = params[:excel_cust_code].blank? ? "" : params[:excel_cust_code]
        @custname = params[:excel_cust_name].blank? ? "" : params[:excel_cust_name]
        @outdate_from = params[:excel_date_from].blank? ? Date.today.try(:strftime, "%Y/%m/%d") : params[:excel_date_from]
        @outdate_to = params[:excel_date_to].blank? ? Date.today.try(:strftime, "%Y/%m/%d") : params[:excel_date_to]
      else
        @routecode = params[:search].blank? ? "" : params[:search][:route]
        @itakucode = params[:search].blank? ? "" : params[:search][:itaku]
        @custcode = params[:search].blank? ? "" : params[:search][:cust_code]
        @custname = params[:search].blank? ? "" : params[:search][:cust_name]
        @outdate_from = params[:search].blank? ? Date.today.try(:strftime, "%Y/%m/%d") : params[:search][:date_from]
        @outdate_to = params[:search].blank? ? Date.today.try(:strftime, "%Y/%m/%d") : params[:search][:date_to]
      end
      @outdate_tom = DateTime.strptime(@outdate_to, "%Y/%m/%d").tomorrow
      @strwhere = "tcl.mikaishu_count is not null"
      if @outdate_from != ""
        @strwhere = @strwhere + " AND t_carruns.out_timing>='#{@outdate_from}'"
      end
      if @outdate_to != ""
        @strwhere = @strwhere + " AND t_carruns.out_timing<'#{@outdate_tom}'"
      end
      if @routecode != ""
        @strwhere = @strwhere + " AND t_carruns.route_code = '#{@routecode}'"
      end
      if @custcode != ""
        @strwhere = @strwhere + " AND tcl.cust_code = '#{@custcode}'"
      end
      if @custname != ""
        @strwhere = @strwhere + " AND tcl.cust_name like '%#{@custname}%'"
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
      @t_collect_lists = @t_collect_lists.joins("left join m_combos mikaishu ON mikaishu.class_1='#{G_MIKAISHU_CLASS_1}' and mikaishu.class_code=tcl.mikaishu_code")
      @t_collect_lists = @t_collect_lists.joins("left join m_customs itaku ON itaku.cust_kbn='#{G_CUST_KBN_GYOSHA}' and itaku.cust_code=m_cars.itaku_code")
      @t_collect_lists = @t_collect_lists.joins("left join (select carrun_id, cust_kbn, cust_code from t_carrun_memos where cust_code<>'*' group by carrun_id, cust_kbn, cust_code) tcm1 on tcm1.carrun_id=t_carruns.id and tcm1.cust_kbn=tcl.cust_kbn and tcm1.cust_code=tcl.cust_code")
      @t_collect_lists = @t_collect_lists.joins("left join (select carrun_id, finish_timing from t_carrun_memos where cust_code='*' group by carrun_id, finish_timing) tcm2 on tcm2.carrun_id=t_carruns.id and tcm2.finish_timing=tcl.finish_timing")
      @t_collect_lists = @t_collect_lists.select("t_carruns.*, tcl.cust_kbn, tcl.cust_code, tcl.cust_name, tcl.finish_timing, tcl.mikaishu_code, tcl.mikaishu_count, m_cars.car_reg_code, m_routes.route_name, mikaishu.class_name as mikaishu_name, itaku.cust_code as itaku_code, itaku.cust_name as itaku_name, case when tcl.cust_code='*' then tcm2.carrun_id else tcm1.carrun_id end as memo_id")
      @t_collect_lists = @t_collect_lists.where("#{@strwhere}")
      @t_collect_lists = @t_collect_lists.order("t_carruns.out_timing desc, t_carruns.id desc, tcl.id desc")
    end
    
    def set_search_params
      @search_param = ""

      @search_params = "/" + params[:carrun_id].to_s
      @search_params = @search_params.to_s + "?collect_flg=" + params[:collect_flg]
      @search_params = @search_params.to_s + "&finish_timing=" + ERB::Util.url_encode(params[:finish_timing])
      @search_params = @search_params.to_s + "&cust_kbn=" + ERB::Util.url_encode(params[:cust_kbn])
      @search_params = @search_params.to_s + "&cust_code=" + ERB::Util.url_encode(params[:cust_code])
      @search_params = @search_params.to_s + "&cust_name=" + ERB::Util.url_encode(params[:cust_name])
      @search_params = @search_params.to_s + "&mikaishu_name=" + ERB::Util.url_encode(params[:mikaishu_name])
      @search_params = @search_params.to_s + "&mikaishu_count=" + ERB::Util.url_encode(params[:mikaishu_count])

    end
end
