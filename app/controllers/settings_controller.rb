class SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def show
  end

  def account
  end

  def profile
  end

  def password
    render_404 if Setting.sso_enabled?
  end

  def reward
  end

  def update
    case params[:by]
    when "password"
      update_password
    when "profile"
      update_profile
    when "reward"
      update_reward
    else
      update_basic
    end
  end

  def destroy
    current_password = params[:user][:current_password]

    unless @user.valid_password?(current_password)
      @user.errors.add(:current_password, :invalid)
      render "show"
      return
    end

    @user.soft_delete
    sign_out
    redirect_to root_path, notice: "Account deleted successfully."
  end

  def auth_unbind
    provider = params[:provider]
    if current_user.authorizations.count <= 1
      redirect_to account_setting_path, notice: t("users.unbind_warning")
      return
    end

    current_user.authorizations.where(provider: provider).delete_all
    redirect_to account_setting_path, notice: t("users.unbind_success", provider: provider.titleize)
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(*User::ACCESSABLE_ATTRS)
  end

  def update_basic
    if @user.update(user_params)
      redirect_to setting_path, notice: "update completed"
    else
      render "show"
    end
  end

  def update_profile
    if @user.update(user_params)
      @user.update_profile_fields(params[:user][:profiles])
      redirect_to profile_setting_path, notice: "update completed"
    else
      render "profile"
    end
  end

  def update_reward
    reward_fields = params[:user][:rewards] || {}

    res = {}
    reward_fields.keys.each do |key|
      photo = Photo.create(image: reward_fields[key])
      res[key] = photo.image.url
    end

    if @user.update_reward_fields(res)
      redirect_to reward_setting_path, notice: "update completed"
    else
      render "reward"
    end
  end

  def update_password
    if @user.update_with_password(user_params)
      redirect_to new_session_path(:user), notice: "Password update is successful, and now you need to re-login."
    else
      render "password"
    end
  end
end
