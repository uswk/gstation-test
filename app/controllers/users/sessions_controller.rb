class Users::SessionsController < Devise::SessionsController

  # GET /resource/sign_in
  def new
    puts "sign_in new"
    super
  end

  # POST /resource/sign_in
  def create
    puts "sign_in create"
    super
    api_log_hists(1501, 0, "")
  end

  # DELETE /resource/sign_out
  #def destroy
  #  super
  #end

  def configure_sign_in_params
    devise_parameter_sanitizer.permit!
  end
end
