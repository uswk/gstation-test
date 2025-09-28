class TCustomMemosController < ApplicationController

  before_action :authenticate_user!
  before_action :set_itaku

  # GET /t_custom_memos
  def index
    @header_no_dsp = 1 #ヘッダ非表示
    
    @cust_kbn = G_CUST_KBN_STATION
    @cust_code = params[:cust_code]
    @m_custom = MCustom.where("cust_kbn=? and cust_code=?", @cust_kbn, @cust_code).first
    @cust_name = @m_custom.cust_name
  
    @memodate_from = params[:search].blank? ? Date.today.years_ago(1).try(:strftime, "%Y/%m/%d") : params[:search][:memodate_from]
    @memodate_to = params[:search].blank? ? Date.today.try(:strftime, "%Y/%m/%d") : params[:search][:memodate_to]
    @itakucode = params[:search].blank? ? "" : params[:search][:itaku]
    @memotype = params[:search].blank? ? "0" : params[:search][:memo_type]
    
    if @memotype.to_s == "0"
      strwhere = "t_custom_memos.cust_kbn='#{@cust_kbn}'"
      strwhere = strwhere +  " and t_custom_memos.cust_code='#{@cust_code}'"
      if @memodate_from != ""
        strwhere = strwhere + " AND t_custom_memos.memo_time>='#{@memodate_from}'"
      end
      if @memodate_to != ""
        @memodate_tom = @memodate_to.to_date+1
        strwhere = strwhere + " AND t_custom_memos.memo_time<'#{@memodate_tom}'"
      end
      if not current_user.itaku_code.blank?
        strwhere = strwhere + " AND (t_custom_memos.itaku_flg=0 or t_custom_memos.itaku_code='#{current_user.itaku_code}')"
      else
        if @itakucode != ""
          strwhere = strwhere + " AND t_custom_memos.itaku_code='#{@itakucode}'"
        end
      end
      
      @t_custom_memos = TCustomMemo.joins("left join m_customs mc ON mc.cust_kbn=t_custom_memos.cust_kbn and mc.cust_code=t_custom_memos.cust_code")
      @t_custom_memos = @t_custom_memos.joins("left join m_customs itaku ON itaku.cust_kbn='#{G_CUST_KBN_GYOSHA}' and itaku.cust_code=t_custom_memos.itaku_code")
      @t_custom_memos = @t_custom_memos.joins("left join users u on u.id=t_custom_memos.user_id")
      @t_custom_memos = @t_custom_memos.page(params[:page]).per("#{G_DEF_PAGE_PER}").where("#{strwhere}")
      @t_custom_memos = @t_custom_memos.select("t_custom_memos.*, mc.cust_name, itaku.cust_name as itaku_name, u.user_name")
      @t_custom_memos = @t_custom_memos.order("t_custom_memos.memo_time desc, t_custom_memos.id desc")
    else
      strwhere = "t_carrun_memos.cust_kbn='#{@cust_kbn}'"
      strwhere = strwhere +  " and t_carrun_memos.cust_code='#{@cust_code}'"
      if @memodate_from != ""
        strwhere = strwhere + " AND t_carrun_memos.finish_timing>='#{@memodate_from}'"
      end
      if @memodate_to != ""
        @memodate_tom = @memodate_to.to_date+1
        strwhere = strwhere + " AND t_carrun_memos.finish_timing<'#{@memodate_tom}'"
      end
      if not current_user.itaku_code.blank?
        strwhere = strwhere + " AND car.itaku_code='#{current_user.itaku_code}'"
      else
        if @itakucode != ""
          strwhere = strwhere + " AND car.itaku_code='#{@itakucode}'"
        end
      end
      
      @t_carrun_memos = TCarrunMemo.joins("inner join t_carruns tc on tc.id=t_carrun_memos.carrun_id")
      @t_carrun_memos = @t_carrun_memos.joins("inner join m_cars car on car.car_code=tc.car_code")
      @t_carrun_memos = @t_carrun_memos.joins("left join m_customs mc ON mc.cust_kbn=t_carrun_memos.cust_kbn and mc.cust_code=t_carrun_memos.cust_code")
      @t_carrun_memos = @t_carrun_memos.joins("left join m_customs itaku ON itaku.cust_kbn='#{G_CUST_KBN_GYOSHA}' and itaku.cust_code=car.itaku_code")
      @t_carrun_memos = @t_carrun_memos.joins("left join m_drivers md on md.driver_code=tc.driver_code")
      @t_carrun_memos = @t_carrun_memos.page(params[:page]).per("#{G_DEF_PAGE_PER}").where("#{strwhere}")
      @t_carrun_memos = @t_carrun_memos.select("t_carrun_memos.*, mc.cust_name, itaku.cust_name as itaku_name, md.driver_name, car.car_reg_code, tc.out_timing")
      @t_carrun_memos = @t_carrun_memos.order("tc.out_timing desc, t_carrun_memos.finish_timing desc, t_carrun_memos.id desc")
    end
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /t_custom_memos/1
  def show
  end

  # GET /t_custom_memos/new
  def new
  end

  # GET /t_custom_memos/1/edit
  def edit
  end

  # POST /t_custom_memos
  def create
    if not params[:update].nil?
      change_comment = params[:update][:cust_code].to_s + ":" + params[:update][:cust_name].to_s
      if params[:update][:flg].to_s == "1"  # メモ登録
        @t_custom_memo = TCustomMemo.new(:cust_kbn => params[:update][:cust_kbn], :cust_code => params[:update][:cust_code], :memo_time => Time.new, :memo => params[:update][:memo], :user_id => current_user.id, :itaku_code => current_user.itaku_code, :itaku_flg => params[:update][:itaku_flg])
        if @t_custom_memo.save
          api_log_hists(303, 1, change_comment)
          @ajax_flg = 1
        else
          @ajax_flg = 9
        end
      elsif params[:update][:flg].to_s == "2" # メモ更新
        @t_custom_memo = TCustomMemo.find(params[:update][:id])
        @t_custom_memo.update(:memo => params[:update][:memo], :itaku_flg => params[:update][:itaku_flg])
        api_log_hists(303, 2, change_comment)
        @ajax_flg = 2
      elsif params[:update][:flg].to_s == "3" # メモ削除
        @t_custom_memo = TCustomMemo.find(params[:update][:id])
        @t_custom_memo.destroy
        api_log_hists(303, 3, change_comment)
        @ajax_flg = 3
      end
    end
  end

  # PATCH/PUT /t_custom_memos/1
  def update
  end

  # DELETE /t_custom_memos/1
  def destroy
  end

  private
    def set_itaku
      #委託会社プルダウン用
      @itaku_codes = MCustom.where("cust_kbn=5 and delete_flg=0").order("cust_code asc").map{|i| [i.cust_code.to_s + ':' + i.cust_name.to_s, i.cust_code] }
    end
end
