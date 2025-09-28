class ConvertsController < ApplicationController

  before_action :authenticate_user!
  
  # GET /converts
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # POST /converts
  def csv

    @hoges = load_csv(params[:file_name])

  end

  private
 
  def load_csv(csv_file)
    require 'csv'   #csv操作を可能にするライブラリ
    require 'kconv' #文字コード操作をよろしくやるライブラリ
    require 'geocoder'
    
    @map_key = A_DEF_MAP_KEY
    #Geocoder.configure(:language => :ja, :units => :km, :timeout => 15, :lookup => :google_premier, :api_key => [@map_key.to_s,'',''] )
    Geocoder.configure(:language => :ja, :units => :km )
    
    if params[:chg_flg]=="2"
      @customs = MCustom.where("cust_kbn=1 and latitude is null")
      @customs.each do |custom|
        @lat = nil
        @lng = nil
        @latlng_flg = 0
        # 読み込み失敗を考慮して読み取れるまでループ。３回読み取れなかったらエラー
        for num in 1..3 do
          @latlng = Geocoder.search(custom.addr_1)
          @latlng = @latlng.to_s.gsub(' ','')
          @latlng = @latlng.to_s.gsub('\n', '')
          @latlng = @latlng.to_s.split('"location"=>')[1]
          @lat = @latlng.to_s.split('"lat"=>')[1]
          @lat = @lat.to_s.split(',')[0]
          @lng = @latlng.to_s.split('"lng"=>')[1]
          @lng = @lng.to_s.split('}')[0]
          if not @lat.blank?
            @latlng_flg = 1
            break;
          end
        end
        if @latlng_flg == 1
          custom.update(:latitude => @lat, :longitude => @lng)
        end
      end
    end
    if params[:chg_flg]=="3"
      @customs = MCustom.where("cust_kbn=1 and latitude is not null and addr_3 is null")
      @customs.each do |custom|
        @address_flg = 0
        # 読み込み失敗を考慮して読み取れるまでループ。３回読み取れなかったらエラー
        for num in 1..3 do
          @latlng = custom.latitude.to_s + "," + custom.longitude.to_s
          @address = Geocoder.address(@latlng)
          @address = @address.to_s.gsub('日本、','')
          @address = @address.to_s.gsub('\n', '')
          if not @address.blank?
            @address_flg = 1
            break;
          end
        end
        if @address_flg == 1
          if custom.memo.blank?
            @memo = ""
          else
            @memo = "\n" + custom.memo.to_s
          end
          @memo = "ステーション名：" + custom.cust_name.to_s + "　\n住所：" + custom.addr_1.to_s + custom.addr_2.to_s + @memo.to_s
          custom.update(:addr_1=> @address, :addr_2 => nil, :memo => @memo, :addr_3 => 1)        end
      end
    end
    if params[:chg_flg]=="1"
      #params[:csv_file]にファイルが格納されているので
      #受け取って文字列にする処理
      charactor = csv_file.read
 
      hoges = []
      i = 0
 
      #kconv(変換したい文字コード, ファイルの文字コード)
      CSV.parse(charactor.kconv(Kconv::UTF8, Kconv::SJIS)) do |row|
      
        cust_name = row[0]
        addr_1 = row[6]
        addr_2  = row[7]

        latitude = row[21]
        longitude = row[22]
        admin_code = nil
        if row[8].to_s.strip=="その他"
        else
          case row[8].to_s.strip
            when "行政区" then
              admin_type = 1
            when "管理会社" then
              admin_type = 2
            when "個人" then
              admin_type = 3
            else
              admin_type = nil
          end
          if not row[12].blank?
            if row[12].length == 7
              admin_tel = "0299-" + row[12].to_s
            else
              admin_tel = row[12]
            end
          else
            admin_tel = ""
          end
          if not row[9].blank?
            @admin = MCustom.where("cust_kbn=2 and cust_name=? and tel_no=? and admin_type=?", row[9].to_s.strip, admin_tel, admin_type).first
            if @admin.nil?
              admin_code = MCustom.where("cust_kbn='#{G_CUST_KBN_ADMIN}'").maximum(:cust_code).to_i + 1
              admin_code = "%05d" % admin_code
              @admin_custom = MCustom.new(:cust_kbn => G_CUST_KBN_ADMIN, :cust_code => admin_code, :cust_name => row[9].to_s.strip, :addr_1 => row[10], :addr_2 => row[11], :tel_no => admin_tel, :admin_type => admin_type, :delete_flg => 0)
              @admin_custom.save
            else
              admin_code = @admin.cust_code
            end
          end
        end
        @use_content = MCombo.where("class_1=9 and class_2=0 and class_name=?", row[5]).first
        if @use_content.nil?
          use_content = nil
        else
          use_content = @use_content.class_code
        end
        if row[13]=="不明" || row[13].blank?
          shinsei_date = nil
        else
          shinsei_date = row[13]
        end
        if row[14]=="不明" || row[14].blank?
          start_date = nil
        else
          start_date = row[14]
        end
        if row[15]=="不明" || row[15].blank?
          setai_count = nil
        else
          setai_count = row[15]
        end
        if row[16]=="不明" || row[16].blank?
          use_count = nil
        else
          use_count = row[16]
        end
        memo = (row[17].to_s + " " + row[20].to_s).strip
        custcode = MCustom.where("cust_kbn='#{G_CUST_KBN_STATION}'").maximum(:cust_code).to_i + 1
        @custcode = "%07d" % custcode
        @m_custom = MCustom.new(:cust_kbn => G_CUST_KBN_STATION, :cust_code => @custcode, :cust_name => cust_name, :addr_1 => addr_1, :addr_2 => addr_2, :latitude => latitude, :longitude => longitude, :admin_code => admin_code, :use_content => use_content, :shinsei_date => shinsei_date, :start_date => start_date, :setai_count => setai_count, :use_count => use_count, :memo => memo, :delete_flg => 0);
        if @m_custom.save
          if not row[3].blank?
            @m_route = MRoute.where("route_name=?", row[3]).first
            #@tree_no = MRoutePoint.where("route_code=?", row[3]).maximum(:tree_no).to_i + 1
            @tree_no = MRoutePoint.where("route_code=?", @m_route.route_code).maximum(:tree_no).to_i + 1
            @m_route_point = MRoutePoint.new(:route_code => row[3], :tree_no => @tree_no, :cust_kbn => G_CUST_KBN_STATION, :cust_code => @custcode)
            @m_route_point.save
          end
        end
      end
    end
  end

end
