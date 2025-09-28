class InfomationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_infomation, only: [:show, :edit, :update, :destroy]

  # GET /infomations
  def index
    @infomations = Infomation.select("infomations.*").order("infomations.info_date desc, infomations.id desc")
  end

  # GET /infomations/1
  def show
  end

  # GET /infomations/new
  def new
    @infomation = Infomation.new
  end

  # GET /infomations/1/edit
  def edit
  end

  # POST /infomations
  def create
    @infomation = Infomation.new(params[:infomation])

    respond_to do |format|
      if @infomation.save
        format.html { redirect_to infomations_path, notice: '登録作業が完了しました。' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /infomations/1
  def update
    @infomation = Infomation.find(params[:id])
    
    respond_to do |format|
      if @infomation.update(params[:infomation])
        format.html { redirect_to infomations_path, notice: '更新作業が完了しました。' }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /infomations/1
  def destroy
    @infomation.destroy
    respond_to do |format|
      format.html { redirect_to infomations_url, notice: '削除作業が完了しました。' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_infomation
      @infomation = Infomation.find(params[:id])
    end

end
