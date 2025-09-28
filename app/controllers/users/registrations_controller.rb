class Users::RegistrationsController < Devise::RegistrationsController

  # GET /resource/sign_up
  def new
    super
  end

  # POST /resource
  def create
    super
  end

  # GET /resource/edit
  def edit
    super
  end

  # PUT /resource
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    if resource.update_with_password(resource_params)
      if is_navigational_format?
        flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ?
          :update_needs_confirmation : :updated
        set_flash_message :notice, flash_key
        api_log_hists(1301, 2, "")
      end
      debugger
      bypass_sign_in resource, scope: resource_name
      respond_with resource, :location => after_update_path_for(resource)
    else
      clean_up_passwords resource
      respond_with resource
    end
  end

  # DELETE /resource
  def destroy
    super
  end

  # GET /resource/cancel
  def cancel
    super
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit!
  end

  def resource_params
    params.require(resource_name).permit([:password, :password_confirmation, :current_password])
  end
end
