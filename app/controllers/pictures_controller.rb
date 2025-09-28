class PicturesController < ApplicationController

  before_action :authenticate

    # POST /pictures                                                                                                                                                              
    # POST /pictures.json
    def index
      #  unless params[:file].blank?
      #    #filename = save_file(params[:file])
      #    if save_file(params[:file])
      #      render nothing: true, status: :ok
      #    else
      #      render nothing: true, :status => 500
      #    end
      #  end
      unless params[:file].blank?

        # トランザクション処理
        begin
          ActiveRecord::Base.transaction do
        
            uploaded_file = params[:file]
            file_name = uploaded_file.original_filename.to_s

            cust_kbn = G_CUST_KBN_STATION
            if file_name.to_s.slice(0, 1)=="*" || file_name.to_s.slice(0, 1)=="a"
              # cust_code = file_name.to_s.slice(0, 1)
              cust_code = "*"
              finish_timing = file_name.to_s.slice(1, 14)
            else
              cust_code = file_name.to_s.slice(0, 7)
              finish_timing = file_name.to_s.slice(7, 14)
            end
            finish_timing = finish_timing.slice(0, 4) + "-" + finish_timing.slice(4, 2) + "-" + finish_timing.slice(6, 2) + " " + finish_timing.slice(8, 2) + ":" + finish_timing.slice(10, 2) + ":" + finish_timing.slice(12, 2)
            car_id = file_name.to_s.split("_")[1]
            out_timing = file_name.to_s.split("_")[2]
            
            if car_id.blank? || out_timing.blank?
              t_carruns = TCarrun.joins("inner join t_collect_lists tcl on tcl.out_timing=t_carruns.out_timing and tcl.car_code=t_carruns.car_code").where("tcl.finish_timing=? and tcl.cust_kbn=? and tcl.cust_code=?", finish_timing, cust_kbn, cust_code).select("t_carruns.id")
            else
              out_timing = out_timing.slice(0, 4) + "-" + out_timing.slice(4, 2) + "-" + out_timing.slice(6, 2) + " " + out_timing.slice(8, 2) + ":" + out_timing.slice(10, 2) + ":" + out_timing.slice(12, 2)
              t_carruns = TCarrun.joins("inner join m_cars mc on mc.car_code=t_carruns.car_code").where("t_carruns.out_timing=? and mc.id=?", out_timing, car_id).select("t_carruns.id")
            end
            carrun_id = nil
            if not t_carruns.blank?
              carrun_id = t_carruns[0].id
            end

            @t_carrun_memos = TCarrunMemo.where("memo_file_name=?", file_name)
            # 同じファイルが存在しなかったら追加
            if not @t_carrun_memos.blank?
              @t_carrun_memos.each do |t_carrun_memo|
                #TCarrunMemo.where("id=?", t_carrun_memos.id).destroy_all
                t_carrun_memo.update!(:carrun_id => carrun_id, :cust_kbn => cust_kbn, :cust_code => cust_code, :finish_timing => finish_timing, :memo => uploaded_file)
              end
            else
              TCarrunMemo.create!(:carrun_id => carrun_id, :cust_kbn => cust_kbn, :cust_code => cust_code, :finish_timing => finish_timing, :memo => uploaded_file)
            end
          end
          render nothing: true, status: :ok
        rescue => e
          render nothing: true, :status => 500
        end
      end
    end

    def save_file(upload)
        require 'fileutils'
        unless upload.original_filename.blank?
          tmp = upload.tempfile
          filename = upload.original_filename
          filedir = "public/images/memo/"
          filepath = File.join(filedir,filename)
  
          FileUtils.cp tmp.path, filepath
          FileUtils.chmod 0755, filepath
          return filename
        end
    end

private
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @company = MCompany.find_by_username_and_password(username, password)
    end
  end

end