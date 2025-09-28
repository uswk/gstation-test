class TOperationsController < ApplicationController

  before_action :authenticate_user!
  before_action :set_work_kind

  # GET /t_operations
  def index
    @header_no_dsp = 1 #ヘッダ非表示
    
    @t_carrun_lists = TCarrunList.joins("left join m_combo_bigs mcb on mcb.class_1=t_carrun_lists.work_kbn").joins("left join m_combos mc on mc.class_1=mcb.class_1 and mc.class_code=t_carrun_lists.work_kind").select("t_carrun_lists.*, mcb.class_name as work_kbn_name, mc.class_name as work_kind_name").where("t_carrun_lists.out_timing=? and t_carrun_lists.car_code=?",params[:out_timing], params[:car_code]).order("t_carrun_lists.work_timing asc, t_carrun_lists.id asc")
    @t_carrun = TCarrun.where("out_timing=? and car_code=?",params[:out_timing], params[:car_code]).first

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /t_operations/1
  def show
  end

  # GET /t_operations/new
  def new
  end

  # GET /t_operations/1/edit
  def edit
  end

  # POST /t_operations
  def create
    if not params[:update].nil?
      @t_carrun = TCarrun.joins("LEFT JOIN m_routes mr on mr.route_code=t_carruns.route_code").select("t_carruns.out_timing, t_carruns.car_code, mr.route_name").where("t_carruns.out_timing=? and t_carruns.car_code=?",params[:update_out_timing], params[:update_car_code]).first
      change_comment = @t_carrun.out_timing.strftime("%Y-%m-%d %H:%M:%S").to_s + "　" + @t_carrun.route_name.to_s
      if params[:update][:flg].to_s == "1"  # 運行データ登録
        @t_carrun_list = TCarrunList.new(:out_timing => @t_carrun.out_timing, :car_code => @t_carrun.car_code, :work_timing => @t_carrun.out_timing.strftime("%Y-%m-%d").to_s + " " + params[:update][:work_timing].to_s, :end_timing => @t_carrun.out_timing.strftime("%Y-%m-%d").to_s + " " + params[:update][:end_timing].to_s, :work_kbn => params[:update][:work_kind].to_s.split("_")[0], :work_kind => params[:update][:work_kind].to_s.split("_")[1])
        if @t_carrun_list.save
          change_comment = change_comment.to_s + "　運行データ登録"
          api_log_hists(201, 2, change_comment)
          @ajax_flg = 1
        else
          @ajax_flg = 9
        end
      elsif params[:update][:flg].to_s == "2" # 運行データ更新
        @t_carrun_list = TCarrunList.find(params[:update][:id])
        @t_carrun_list.update(:work_timing => @t_carrun.out_timing.strftime("%Y-%m-%d").to_s + " " + params[:update][:work_timing].to_s, :end_timing => @t_carrun.out_timing.strftime("%Y-%m-%d").to_s + " " + params[:update][:end_timing].to_s, :work_kbn => params[:update][:work_kind].to_s.split("_")[0], :work_kind => params[:update][:work_kind].to_s.split("_")[1])
        change_comment = change_comment.to_s + "　運行データ更新"
        api_log_hists(201, 2, change_comment)
        @ajax_flg = 2
      elsif params[:update][:flg].to_s == "3" # 運行データ削除
        @t_carrun_list = TCarrunList.find(params[:update][:id])
        @t_carrun_list.destroy
        change_comment = change_comment.to_s + "　運行データ削除"
        api_log_hists(201, 2, change_comment)
        @ajax_flg = 3
      end
    end
  end

  # PATCH/PUT /t_operations/1
  def update
  end

  # DELETE /t_operations/1
  def destroy
  end

  private
    def set_work_kind
      @work_kinds = MCombo.joins("inner join m_combo_bigs mcb on mcb.class_1=m_combos.class_1").select("m_combos.*, concat(m_combos.class_1, '_', m_combos.class_code) as work_kind, concat(mcb.class_name, '：', m_combos.class_name) as work_kind_name").where("mcb.system_name like 'ope%' and m_combos.delete_flg=0").order("m_combos.class_1 asc, m_combos.class_code asc").map{|i| [i.work_kind_name.to_s, i.work_kind] }
    end
end
