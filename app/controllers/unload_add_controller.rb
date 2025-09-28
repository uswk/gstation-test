class UnloadAddController < ApplicationController

  before_action :authenticate_user!
  before_action :set_map_key
  require 'nkf'

  # GET /unload_add
  def index

    @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
    
    if params[:lat_del]
      @def_lat = params[:lat_del]
      @def_lng = params[:lng_del]
      @def_zoom = params[:zoom_del]
    else
      @def_lat = A_DEF_LATITUDE
      @def_lng = A_DEF_LONGITUDE
      @def_zoom = 18
    end
    @def_address = A_DEF_ADDRESS

    @indust_kbns = MCombo.where("class_1='#{G_ITEM_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
    @unit_kbns = MCombo.where("class_1='#{G_UNIT_CLASS_1}' and class_2=0 and delete_flg=0").order("class_code asc").map{|i| [i.class_name, i.class_code] }
    render
  end

  # POST /unload_add
  def ajax
    if params[:chg_flg_new]
      if params[:latitude_new]
        # 重複チェック
        @custom_check = MCustom.where("cust_kbn='#{G_CUST_KBN_UNLOAD}' and cust_name=? and latitude=? and longitude=? and delete_flg=0", params[:cust_name_new][0], params[:latitude_new][0], params[:longitude_new][0]).first
        if @custom_check.nil?
          # ステーション・収集区登録
          custcode = MCustom.where("cust_kbn='#{G_CUST_KBN_UNLOAD}'").maximum(:cust_code).to_i + 1
          @custcode = "%07d" % custcode
          
          @m_custom = MCustom.new(:cust_kbn => G_CUST_KBN_UNLOAD, :cust_code => @custcode, :cust_name => params[:cust_name_new][0], :addr_1 => params[:address_new][0], :addr_2 => params[:addr_2_new][0], :latitude => params[:latitude_new][0], :longitude => params[:longitude_new][0], :memo => params[:memo_new][0], :delete_flg => 0);
          if @m_custom.save
            @tree_no = 0
            params[:cnt_no].to_i.times do |i|
              if not params[:indust_kbn].nil?
                if not params[:indust_kbn][i].nil?
                  @tree_no = @tree_no + 1
                  @m_collect_indust = MCollectIndust.new(:cust_kbn => @m_custom.cust_kbn, :cust_code => @m_custom.cust_code, :indust_kbn =>params[:indust_kbn][i] , :tree_no=> @tree_no, :unit_kbn => params[:unit_kbn][i])
                  @m_collect_indust.save
                end
              end
            end
            
            change_comment = @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
            api_log_hists(1701, 1, change_comment)
            @ajaxflg = 2
          else
            @ajaxflg = -1
          end
        else
          # 重複していた場合
          @ajaxflg = -2
        end
      end
    end
    #ステーション削除
    if params[:delete_flg]=="1"
      @m_custom = MCustom.find(params[:id])
      @m_custom.update(:delete_flg => 1)
      change_comment = @m_custom.cust_code.to_s + ":" + @m_custom.cust_name.to_s
      api_log_hists(1701, 3, change_comment)
      @ajaxflg = 3
    end
    #マーカー再描画
    if params[:marker_flg]
      @now_date = Date.today.try(:strftime, "%Y/%m/%d") # 現在の日付を取得
      routecode = params[:routecode_marker][0]
      northeast_lat = params[:northeast_lat][0]
      southwest_lat = params[:southwest_lat][0]
      northeast_lng = params[:northeast_lng][0]
      southwest_lng = params[:southwest_lng][0]
      
      @m_customs = MCustom.where("m_customs.delete_flg=0 AND m_customs.cust_kbn='#{G_CUST_KBN_UNLOAD}' AND m_customs.latitude<='#{northeast_lat}' AND m_customs.latitude>='#{southwest_lat}' AND m_customs.longitude<='#{northeast_lng}' AND m_customs.longitude>='#{southwest_lng}'")
      @m_customs = @m_customs.select("m_customs.*, 0 AS seq_id")
      @m_customs = @m_customs.order("m_customs.cust_code")

      iCount = 0
      @m_customs.each do |custom|
        @m_customs[iCount].seq_id = iCount
        iCount = iCount + 1
      end

      @ajaxflg = 4
    end
  end
  
  private
  
  def set_map_key
    @map_key = A_DEF_MAP_KEY
  end
  
end
