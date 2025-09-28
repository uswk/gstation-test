class MpcController < ApplicationController

  # before_action :authenticate_user!
  before_action :authenticate
  skip_before_action :verify_authenticity_token

  layout false

  # POST /
  def index
    p = get_param
    ActiveRecord::Base.transaction do
      p["data"].each do |data| # data should be Array
        data.each {|data_type, body| process_data(data_type, body)}
      end
    end
  end

  # GET /mpc/users
  def users
    if User.where("user_id=? and authority=1 and login_authority=1", params[:user_id]).first.valid_password?(params[:password])
      render :json => 1
    else
      render :json => 0
    end
  end

  # GET mcars
   # GET mcars.json
  def mcars
    @m_cars = MCar.where("delete_flg = 0")
    respond_to do |format|
      format.json { render :json => @m_cars.to_json }
      format.html { render :text => "<pre>#{JSON.pretty_generate(@m_cars.as_json)}</pre>" }
    end
  end

  # GET mcars
  # GET mcars.json
  def mdrivers
    @m_drivers = MDriver.where("delete_flg = 0")
    respond_to do |format|
      format.json { render :json => @m_drivers.to_json }
      format.html { render :text => "<pre>#{JSON.pretty_generate(@m_drivers.as_json)}</pre>" }
    end
  end

  # GET mroutes/:car_code
  # GET mroutes.json

  def mroutes
    car_code = params[:car_code]
       if car_code == "all"
        @m_routes = MRoute.where("delete_flg = 0")
       else
           @m_routes = MRoute.where("car_code =? and delete_flg = 0", car_code)
       end
    respond_to do |format|
      format.json { render :json => @m_routes.to_json }
      format.html { render :text => "<pre>#{JSON.pretty_generate(@m_routes.as_json)}</pre>" }
    end
  end
  
  # GET route_areas/:route_code
  def route_areas

    @m_route_areas = MRouteArea.where("route_code=?", params[:route_code]).select("id, route_code, tree_no, latlng, last_up_user, created_at, updated_at").order("tree_no, id")
    respond_to do |format|
      format.json { render :json => @m_route_areas.to_json }
      format.html { render :text => "<pre>#{JSON.pretty_generate(@m_route_areas.as_json)}</pre>" }
    end
  end
  
  # GET route_recommends/:route_code
  def route_recommends

    @m_route_recommend = MRouteRecommend.where("route_code=?", params[:route_code]).select("id, route_code, priority, latlng, carrun_id, created_at, updated_at").order("priority, id").first
    respond_to do |format|
      format.json { render :json => @m_route_recommend.to_json }
      format.html { render :text => "<pre>#{JSON.pretty_generate(@m_route_recommend.as_json)}</pre>" }
    end
  end
  
  # GET mcustoms
  # GET mcustoms.json

  def mcustoms
    @m_customs = MCustom.where("delete_flg = 0")
    respond_to do |format|
      format.json { render :json => @m_customs.to_json }
      format.html { render :text => "<pre>#{JSON.pretty_generate(@m_customs.as_json)}</pre>" }
    end
  end

  # GET mcombobigss
  # GET mcombobigs.json

  def mcombobigs
    @m_combobigs = MComboBig.where("delete_flg = 0")
    respond_to do |format|
      format.json { render :json => @m_combobigs.to_json }
      format.html { render :text => "<pre>#{JSON.pretty_generate(@m_combobigs.as_json)}</pre>" }
    end
  end

  # GET mcombos
  # GET mcombos.json

  def mcombos
    @m_combos = MCombo.where("delete_flg = 0")
    respond_to do |format|
      format.json { render :json => @m_combos.to_json }
      format.html { render :text => "<pre>#{JSON.pretty_generate(@m_combos.as_json)}</pre>" }
    end
  end

  def mitakus
    @m_itakus = MCustom.where("cust_kbn=5 and delete_flg = 0")
    respond_to do |format|
      format.json { render :json => @m_itakus.to_json }
      format.html { render :text => "<pre>#{JSON.pretty_generate(@m_itakus.as_json)}</pre>" }
    end
  end

  # GET mroutepoints/:route_code
  # GET mroutepoints.json
  def mroutepoints
    route_code = params[:route_code]
    @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
    
    select_sql = "m_route_points.id, m_route_points.route_code, @i:=@i+1 as tree_no, m_route_points.cust_kbn, m_route_points.cust_code, mc.cust_name, mc.cust_namek, mc.latitude, mc.longitude, mc.zip_code, mc.addr_1, mc.addr_2, mc.addr_3, mc.tel_no, mc.fax_no, mc.memo, mc.delete_flg, mc.email, mc.admin_code, mc.admin_type, mc.use_content, mc.shinsei_date, mc.haishi_date, mc.start_date, mc.end_date, mc.setai_count, mc.use_count, mc.district_code, mc.district_name, mc.seq, mc.icon_file_name, '' as pic_url"
    @m_routepoints = MRoutePoint.joins("inner join m_customs mc on mc.cust_kbn=m_route_points.cust_kbn and mc.cust_code=m_route_points.cust_code")
    @m_routepoints = @m_routepoints.joins("cross join (select @i:=0) as cnt")
    @m_routepoints = @m_routepoints.where("m_route_points.route_code=? and mc.delete_flg=0 and ((mc.start_date is null OR mc.start_date<='#{@now_date}') AND (mc.end_date is null OR mc.end_date>='#{@now_date}'))", route_code)
    @m_routepoints = @m_routepoints.select(select_sql)
    @m_routepoints = @m_routepoints.order("m_route_points.tree_no asc, m_route_points.id asc")
    
    iCount = 0
    @m_routepoints.each do |routepoint|
      if not routepoint.icon_file_name.blank?
        @m_custom = MCustom.where("cust_kbn=? and cust_code=?", routepoint.cust_kbn, routepoint.cust_code)
        if not @m_custom[0].icon.blank?
          @m_routepoints[iCount].pic_url = @m_custom[0].icon.url(:original).to_s
        end
      end
      iCount = iCount + 1
    end
    
    respond_to do |format|
      format.json { render :json => @m_routepoints.to_json }
      format.html { render :text => "<pre>#{JSON.pretty_generate(@m_routepoints.as_json)}</pre>" }
    end
  end

  # GET mrouterundates/:route_code
  # GET mrouterundates.json
  def mrouterundates
    route_code = params[:route_code]
    if route_code == "all"
        @m_routerundates = MRouteRundate.where("1=1")
    else
        @m_routerundates = MRouteRundate.where("route_code =?", route_code)
    end
    respond_to do |format|
      format.json { render :json => @m_routerundates.to_json }
      format.html { render :text => "<pre>#{JSON.pretty_generate(@m_routerundates.as_json)}</pre>" }
    end
  end

  # GET /mpc/t_car_messages
  def t_car_messages
    strwhere = "car_id='#{params[:car_id]}'"
    # 期間抽出
    strwhere = strwhere + " and (start_date is null or start_date <= '#{Date.today}')"
    strwhere = strwhere + " and (end_date is null or end_date >= '#{Date.today}')"
    @t_car_messages = TCarMessage.where("#{strwhere}").order("id")
    respond_to do |format|
      format.json { render :json => @t_car_messages.to_json }
      format.html { render :text => "<pre>#{JSON.pretty_generate(@t_car_messages.as_json)}</pre>" }
    end
  end
  
  # PUT /mpc/t_car_messages/:id
  def update_t_car_message
    p = get_param
    #t_car_message_params = params.slice(:response_answer, :response_time)
    t_car_message = TCarMessage.find(params[:id])
    #if t_car_message.update(t_car_message_params)
    if t_car_message.update(:response_time => p["response_time"], :response_answer => p["response_answer"])
      render nothing: true, status: :ok
    else
      render json: t_car_message.errors.full_messages.to_json, status: :unprocessable_entity
    end
  end

  # GET tcarruns/:date/:route_code
  # GET tcarruns.json
  def tcarruns
    date = params[:date]
       route_code = params[:route_code]

    @t_carruns = TCarrun.where("out_timing >=? and route_code = ?", date, route_code)
    respond_to do |format|
      format.json { render :json => @t_carruns.to_json }
      format.html { render :text => "<pre>#{JSON.pretty_generate(@t_carruns.as_json)}</pre>" }
    end
  end

  # GET tcollectlists/:date/:car_code/:route_code
  # GET tcollectlists.json
  def tcollectlists
    date = params[:date]
    car_code = params[:car_code]
    route_code = params[:route_code]
    finish_timing = date[0,4] + "-" + date[4,2] + "-" + date[6,2]
    out_timing = finish_timing + " " + date[8,2] + ":" + date[10,2] + ":" + date[12,2]

    @t_collect_lists = TCollectList.joins("inner join t_carruns tc on tc.out_timing=t_collect_lists.out_timing and tc.car_code=t_collect_lists.car_code").where("tc.route_code=? and t_collect_lists.finish_timing > ? and not (t_collect_lists.out_timing = ? and t_collect_lists.car_code = ?) ", route_code, finish_timing, out_timing, car_code).select("t_collect_lists.id, t_collect_lists.out_timing, t_collect_lists.car_code, t_collect_lists.spot_no, t_collect_lists.cust_kbn, t_collect_lists.cust_code, t_collect_lists.finish_timing, t_collect_lists.leave_timing, t_collect_lists.arrive_timing, t_collect_lists.mikaishu_count, t_collect_lists.mikaishu_code")
    respond_to do |format|
      format.json { render :json => @t_collect_lists.to_json }
      format.html { render :text => "<pre>#{JSON.pretty_generate(@t_collect_lists.as_json)}</pre>" }
    end
  end

  # GET unloads
  # GET unloads.json
  def unloads
    @unloads = MCustom.joins("left join m_collect_industs mci on mci.cust_kbn=m_customs.cust_kbn and mci.cust_code=m_customs.cust_code")
    @unloads = @unloads.joins("left join m_combos item on item.class_1='#{G_ITEM_CLASS_1}' and item.class_code=mci.indust_kbn")
    @unloads = @unloads.joins("left join m_combos unit on unit.class_1='#{G_UNIT_CLASS_1}' and unit.class_code=mci.unit_kbn")
    @unloads = @unloads.select("m_customs.id, m_customs.cust_kbn, m_customs.cust_code, m_customs.cust_name, m_customs.latitude, m_customs.longitude, m_customs.zip_code, m_customs.addr_1, m_customs.addr_2, m_customs.addr_3, m_customs.memo, group_concat(DISTINCT CONCAT('''',cast(ifnull(mci.indust_kbn,'') as char),'''=>{''indust_name''=>''',ifnull(item.class_name,''),''',''unit_kbn''=>''',cast(ifnull(mci.unit_kbn,'0') as char),''',''unit_name''=>''',ifnull(unit.class_name,' '),'''}') ORDER BY mci.indust_kbn, mci.id SEPARATOR ',') as indust")
    @unloads = @unloads.where("m_customs.delete_flg=0 and m_customs.cust_kbn=?", G_CUST_KBN_UNLOAD)
    @unloads = @unloads.group("m_customs.id").order("m_customs.id")
    @iCount = 0
    @unloads.each do |unload|
      json = unload.indust.to_s
      @unloads[@iCount].indust = eval("{#{json}}")
      @iCount = @iCount + 1
    end
    respond_to do |format|
      format.json { render :json => @unloads.to_json }
      format.html { render :text => "<pre>#{JSON.pretty_generate(@unloads.as_json)}</pre>" }
    end
  end

  def process_data(type, body)
    self.send("process_#{type}", body)
  end

  def process_out p
    carrun = TCarrun.new(p)
    errors = TCarrun.out(carrun)
    if errors!=1
      raise errors.to_json if errors
      @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
      @now_yobi = carrun.out_timing.wday # 現在の曜日を取得
      @now_week = ((carrun.out_timing.day+6)/7).truncate # 現在の週を取得
      
      @m_routepoints = MRoutePoint.joins("inner join m_customs mc on mc.cust_kbn=m_route_points.cust_kbn and mc.cust_code=m_route_points.cust_code")
      @m_routepoints = @m_routepoints.joins("cross join (select @i:=0) as cnt")
      @m_routepoints = @m_routepoints.where("m_route_points.route_code =? and mc.delete_flg=0 and ((mc.start_date is null OR mc.start_date<='#{@now_date}') AND (mc.end_date is null OR mc.end_date>='#{@now_date}'))", carrun.route_code)
      @m_routepoints = @m_routepoints.select("m_route_points.id, m_route_points.route_code, @i:=@i+1 as tree_no, m_route_points.cust_kbn, m_route_points.cust_code, mc.cust_name, mc.latitude, mc.longitude, mc.delete_flg")
      @m_routepoints = @m_routepoints.order("m_route_points.tree_no asc, m_route_points.id asc")
      @m_routepoints.each do |routepoint|
        collect_record = TCollectList.where(:car_code => carrun.car_code, :out_timing => carrun.out_timing, :spot_no => routepoint.tree_no).first
        if not collect_record
          t_collect_list = TCollectList.new(:out_timing => carrun.out_timing, :car_code => carrun.car_code, :spot_no => routepoint.tree_no, :cust_kbn => routepoint.cust_kbn, :cust_code => routepoint.cust_code, :cust_name => routepoint.cust_name, :latitude=> routepoint.latitude, :longitude=> routepoint.longitude, :delete_flg=> routepoint.delete_flg)
          errors =  t_collect_list.errors.full_messages unless t_collect_list.save
          raise errors.to_json if errors
          #if carrun.use_item_flg.to_s=="1"
          #  strwhere = ""
          #  if not p.itaku_code.blank?
          #    strwhere = " and itaku_code='#{p.itaku_code}'"
          #  end
          #  @m_routerundates = MRouteRundate.where("route_code=? and ((rr.run_week=0 AND rr.run_yobi=?) OR (rr.run_week=? AND rr.run_yobi=?))" + strwhere.to_s, carrun.route_code, @now_yobi, @now_week, @now_yobi)
          #  @m_routerundates = @m_routerundates.select("route_code, item_kbn, max(unit_kbn) as unit_kbn")
          #  @m_routerundates = @m_routerundates.group("route_code, item_kbn")
          #  @m_routerundates.each do |routerundate|
          #    t_collect_detail = TCollectDetail.new(:out_timing => carrun.out_timing, :car_code => carrun.car_code, :spot_no => routepoint.tree_no, :item_kbn => routerundate.item_kbn, :unit_kbn => routerundate.unit_kbn)
          #    errors =  t_collect_detail.errors.full_messages unless t_collect_detail.save
          #    raise errors.to_json if errors
          #  end
          #end
        end
      end
    end
  end

  def process_in p
    carrun = TCarrun.new(p)
    errors = TCarrun.in(carrun)
    raise errors.to_json if errors
  end

  def process_status p

# 一時的に外す
    carrunlist = TCarrunList.new(p)
    #errors = TCarrunList.status(carrunlist)
    errors = nil
    
    t_track = TTrack.new(:out_timing => carrunlist.out_timing, :car_code => carrunlist.car_code, :time => carrunlist.work_timing, :latitude => carrunlist.latitude, :longitude => carrunlist.longitude)
    t_track.save

    raise errors.to_json if errors
  end

  def process_collect p
    # t_collect_lists
    t_collect_list = TCollectList.new(p)
    collect_record = TCollectList.where(:car_code => t_collect_list.car_code,:out_timing => t_collect_list.out_timing,:spot_no => t_collect_list.spot_no).first

    if collect_record
      if t_collect_list.delete_flg.to_s=="1"
        collect_details = TCollectDetail.where(:car_code => t_collect_list.car_code,:out_timing => t_collect_list.out_timing,:spot_no => t_collect_list.spot_no)
        errors = collect_details.errors.full_messages unless collect_details.delete_all
        raise errors.to_json if errors
        errors =  collect_record.errors.full_messages unless collect_record.destroy
        raise errors.to_json if errors
      elsif !t_collect_list.arrive_timing.blank? and !collect_record.arrive_timing.blank?
        if t_collect_list.arrive_timing.to_time < collect_record.arrive_timing.to_time
        else
          collect_record.finish_timing = t_collect_list.finish_timing
          collect_record.leave_timing = t_collect_list.leave_timing
          collect_record.arrive_timing = t_collect_list.arrive_timing
          collect_record.mikaishu_count = t_collect_list.mikaishu_count
          collect_record.mikaishu_code = t_collect_list.mikaishu_code
          errors =  collect_record.errors.full_messages unless collect_record.save
          raise errors.to_json if errors
        end
      else
        collect_record.finish_timing = t_collect_list.finish_timing
        collect_record.leave_timing = t_collect_list.leave_timing
        collect_record.arrive_timing = t_collect_list.arrive_timing
        collect_record.mikaishu_count = t_collect_list.mikaishu_count
        collect_record.mikaishu_code = t_collect_list.mikaishu_code
        errors =  collect_record.errors.full_messages unless collect_record.save
        raise errors.to_json if errors
      end
    else
      errors =  t_collect_list.errors.full_messages unless t_collect_list.save
      raise errors.to_json if errors
    end
    
    # t_collect_details
    t_collect_details = p.delete("details")
    
    if t_collect_details
      t_collect_details.each do |collect_detail|
        t_collect_detail = TCollectDetail.new(collect_detail.merge(:out_timing => t_collect_list.out_timing, :car_code => t_collect_list.car_code, :spot_no => t_collect_list.spot_no))
        detail_record = TCollectDetail.where(:car_code => t_collect_list.car_code,:out_timing => t_collect_list.out_timing,:spot_no => t_collect_list.spot_no,:item_kbn => t_collect_detail.item_kbn).first
        if detail_record
          if t_collect_list.delete_flg.to_s=="1"
            errors = detail_record.errors.full_messages unless detail_record.destroy
            raise errors.to_json if errors
          else
            detail_record.item_count = t_collect_detail.item_count
            detail_record.item_weight = t_collect_detail.item_weight
            detail_record.unit_kbn = t_collect_detail.unit_kbn
            errors = detail_record.errors.full_messages unless detail_record.save
            raise errors.to_json if errors
          end
        else
          errors = t_collect_detail.errors.full_messages unless t_collect_detail.save
          raise errors.to_json if errors
        end
      end
    end
  end

  def process_track p
    t_track = TTrack.new(p)
    errors = TTrack.track(t_track)
    rails errors.to_json if errors
  end

  def process_gass p
    t_fee_gass = TFeeGass.new(p)
    fee_gass_record = TFeeGass.where(:car_code => t_fee_gass.car_code,:out_timing => t_fee_gass.out_timing,:gass_timing => t_fee_gass.gass_timing).first

    if fee_gass_record
      if p["delete_flg"].to_s=="1"
        errors =  fee_gass_record.errors.full_messages unless fee_gass_record.destroy
        raise errors.to_json if errors
      else
        fee_gass_record.gass_kbn = t_fee_gass.gass_kbn
        fee_gass_record.quantity = t_fee_gass.quantity
        fee_gass_record.amount = t_fee_gass.amount
        errors =  fee_gass_record.errors.full_messages unless fee_gass_record.save
        raise errors.to_json if errors
      end
    else
      errors =  t_fee_gass.errors.full_messages unless t_fee_gass.save
      raise errors.to_json if errors
    end
  end
  
  def process_carrunlist p
    t_carrun_list = TCarrunList.new(p)
    if t_carrun_list.work_kbn.to_s=="#{G_OPERATION_INSPEC_1}"
      carrun_list_record = TCarrunList.where(:car_code => t_carrun_list.car_code,:out_timing => t_carrun_list.out_timing,:work_kind => t_carrun_list.work_kind,:work_kbn => t_carrun_list.work_kbn).first
    else
      carrun_list_record = TCarrunList.where(:car_code => t_carrun_list.car_code,:out_timing => t_carrun_list.out_timing,:work_kind => t_carrun_list.work_kind,:work_kbn => t_carrun_list.work_kbn,:work_timing => t_carrun_list.work_timing).first
    end
    if carrun_list_record
      carrun_list_record.latitude = t_carrun_list.latitude
      carrun_list_record.longitude = t_carrun_list.longitude
      carrun_list_record.address = t_carrun_list.address
      carrun_list_record.end_timing = t_carrun_list.end_timing
      carrun_list_record.note = t_carrun_list.note

      errors =  carrun_list_record.errors.full_messages unless carrun_list_record.save
      raise errors.to_json if errors
    else
      errors =  t_carrun_list.errors.full_messages unless t_carrun_list.save
      raise errors.to_json if errors
    end
  end

  def get_param
    params[:mpc]
  end

private
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @company = MCompany.find_by_username_and_password(username, password)
    end
  end
end
