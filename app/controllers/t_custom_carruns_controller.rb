class TCustomCarrunsController < ApplicationController

  before_action :authenticate_user!
  before_action :set_itaku

  # GET /t_custom_carruns
  def index
    @header_no_dsp = 1 #ヘッダ非表示
    
    @cust_kbn = params[:cust_kbn]
    @cust_code = params[:cust_code]
    @m_custom = MCustom.where("cust_kbn=? and cust_code=?", @cust_kbn, @cust_code).first
    @cust_name = @m_custom.cust_name
  
    @date_from = params[:search].blank? ? Date.today.months_ago(1).try(:strftime, "%Y/%m/%d") : params[:search][:date_from]
    @date_to = params[:search].blank? ? Date.today.try(:strftime, "%Y/%m/%d") : params[:search][:date_to]
    @itakucode = params[:search].blank? ? "" : params[:search][:itaku]
    
    strwhere = "tcl.cust_kbn='#{@cust_kbn}'"
    strwhere = strwhere +  " and tcl.cust_code='#{@cust_code}'"
    if @date_from != ""
      strwhere = strwhere + " AND tcl.finish_timing>='#{@date_from}'"
    end
    if @date_to != ""
      @date_tom = @date_to.to_date+1
      strwhere = strwhere + " AND tcl.finish_timing<'#{@date_tom}'"
    end
    if not current_user.itaku_code.blank?
      strwhere = strwhere + " AND car.itaku_code='#{current_user.itaku_code}'"
    else
      if @itakucode != ""
        strwhere = strwhere + " AND car.itaku_code='#{@itakucode}'"
      end
    end
    
    @t_custom_carruns = TCarrun.joins("inner join t_collect_lists tcl ON tcl.out_timing=t_carruns.out_timing and tcl.car_code=t_carruns.car_code")
    @t_custom_carruns = @t_custom_carruns.joins("left join m_customs mc on mc.cust_kbn=tcl.cust_kbn and mc.cust_code=tcl.cust_code")
    @t_custom_carruns = @t_custom_carruns.joins("left join m_cars car on car.car_code=t_carruns.car_code")
    @t_custom_carruns = @t_custom_carruns.joins("left join m_customs itaku ON itaku.cust_kbn='#{G_CUST_KBN_GYOSHA}' and itaku.cust_code=car.itaku_code")
    @t_custom_carruns = @t_custom_carruns.joins("left join m_drivers md on md.driver_code=t_carruns.driver_code")
    @t_custom_carruns = @t_custom_carruns.joins("left join m_combos mi on mi.class_1='#{G_MIKAISHU_CLASS_1}' AND mi.class_2=0 and mi.class_code=tcl.mikaishu_code")
    @t_custom_carruns = @t_custom_carruns.joins("left join (select carrun_id, cust_kbn, cust_code from t_carrun_memos where cust_code<>'*' group by carrun_id, cust_kbn, cust_code) tcm on tcm.carrun_id=t_carruns.id and tcm.cust_kbn=tcl.cust_kbn and tcm.cust_code=tcl.cust_code")
    @t_custom_carruns = @t_custom_carruns.page(params[:page]).per("#{G_DEF_PAGE_PER}").where("#{strwhere}")
    @t_custom_carruns = @t_custom_carruns.select("t_carruns.*, tcl.finish_timing, tcl.cust_kbn, tcl.cust_code, tcl.mikaishu_count, tcl.mikaishu_code, mc.cust_name, car.car_reg_code, md.driver_name, itaku.cust_name as itaku_name, mi.class_name as mikaishu_name, tcm.carrun_id as memo_flg")
    @t_custom_carruns = @t_custom_carruns.order("tcl.finish_timing desc, tcl.id desc")

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  private
    def set_itaku
      #委託会社プルダウン用
      @itaku_codes = MCustom.where("cust_kbn=5 and delete_flg=0").order("cust_code asc").map{|i| [i.cust_code.to_s + ':' + i.cust_name.to_s, i.cust_code] }
    end
end
