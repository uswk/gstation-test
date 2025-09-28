class TFeeGassesController < ApplicationController

  before_action :authenticate_user!
  before_action :set_gass_kbn

  # GET /t_fee_gasss
  def index
    @header_no_dsp = 1 #ヘッダ非表示
    
    @t_fee_gasses = TFeeGass.joins("left join m_combos mc on mc.class_1='#{G_FEE_GASS_1}' and mc.class_code=t_fee_gasses.gass_kbn").select("t_fee_gasses.*, mc.class_name as gass_kbn_name").where("t_fee_gasses.out_timing=? and t_fee_gasses.car_code=?",params[:out_timing], params[:car_code]).order("t_fee_gasses.gass_timing asc, t_fee_gasses.id asc")
    @t_carrun = TCarrun.where("out_timing=? and car_code=?",params[:out_timing], params[:car_code]).first

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /t_fee_gasses/1
  def show
  end

  # GET /t_fee_gasses/new
  def new
  end

  # GET /t_fee_gasses/1/edit
  def edit
  end

  # POST /t_fee_gasses
  def create
    if not params[:update].nil?
      @t_carrun = TCarrun.joins("LEFT JOIN m_routes mr on mr.route_code=t_carruns.route_code").select("t_carruns.out_timing, t_carruns.car_code, mr.route_name").where("t_carruns.out_timing=? and t_carruns.car_code=?",params[:update_out_timing], params[:update_car_code]).first
      change_comment = @t_carrun.out_timing.strftime("%Y-%m-%d %H:%M:%S").to_s + "　" + @t_carrun.route_name.to_s
      if params[:update][:flg].to_s == "1"  # 給油登録
        @t_fee_gass_check = TFeeGass.where("out_timing=? and car_code=? and gass_timing=?", @t_carrun.out_timing, @t_carrun.car_code, @t_carrun.out_timing.strftime("%Y-%m-%d").to_s + " " + params[:update][:gass_timing].to_s)
        if @t_fee_gass_check.blank?
          @t_fee_gass = TFeeGass.new(:out_timing => @t_carrun.out_timing, :car_code => @t_carrun.car_code, :gass_timing => @t_carrun.out_timing.strftime("%Y-%m-%d").to_s + " " + params[:update][:gass_timing].to_s, :gass_kbn => params[:update][:gass_kbn], :quantity => params[:update][:quantity])
          if @t_fee_gass.save
            change_comment = change_comment.to_s + "　給油登録"
            api_log_hists(201, 2, change_comment)
            @ajax_flg = 1
          else
            @ajax_flg = 9
          end
        else
          @ajax_flg = 8
        end
      elsif params[:update][:flg].to_s == "2" # 給油更新
        @t_fee_gass_check = TFeeGass.where("out_timing=? and car_code=? and gass_timing=? and id<>?", @t_carrun.out_timing, @t_carrun.car_code, @t_carrun.out_timing.strftime("%Y-%m-%d").to_s + " " + params[:update][:gass_timing].to_s, params[:update][:id])
        if @t_fee_gass_check.blank?
          @t_fee_gass = TFeeGass.find(params[:update][:id])
          @t_fee_gass.update(:gass_timing => @t_carrun.out_timing.strftime("%Y-%m-%d").to_s + " " + params[:update][:gass_timing].to_s, :gass_kbn => params[:update][:gass_kbn], :quantity => params[:update][:quantity])
          change_comment = change_comment.to_s + "　給油更新"
          api_log_hists(201, 2, change_comment)
          @ajax_flg = 2
        else
          @ajax_flg = 8
        end
      elsif params[:update][:flg].to_s == "3" # 給油削除
        @t_fee_gass = TFeeGass.find(params[:update][:id])
        @t_fee_gass.destroy
        change_comment = change_comment.to_s + "　給油削除"
        api_log_hists(201, 2, change_comment)
        @ajax_flg = 3
      end
    end
  end

  # PATCH/PUT /t_fee_gasses/1
  def update
  end

  # DELETE /t_fee_gasses/1
  def destroy
  end

  private
    def set_gass_kbn
      #給油区分プルダウン用
      @gass_kbns = MCombo.where("class_1='#{G_FEE_GASS_1}' and delete_flg=0").order("class_code asc").map{|i| [i.class_name.to_s, i.class_code] }
    end
end
