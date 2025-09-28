class ManualController < ApplicationController

  before_action :authenticate_user!

  #操作マニュアルダウンロード
  def index
    if params[:id].to_s=="1"
      file_name="gstation_manual.pdf"
    else
      file_name="gstation_tablet_manual.pdf"
    end
    filepath = Rails.root.join('public/images',file_name)
    stat = File::stat(filepath)
    send_file(filepath, :filename => file_name, :length => stat.size)
  end

end
