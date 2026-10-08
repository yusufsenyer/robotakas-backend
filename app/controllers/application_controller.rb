class ApplicationController < ActionController::API
  include ActionController::Cookies

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_user!
    return if current_user

    render_error(code: "unauthorized", message: "Giriş yapmalısın.", status: :unauthorized)
    false
  end

  def require_admin!
    return false if require_user! == false
    return if current_user.admin?

    render_error(code: "forbidden", message: "Bu işlem için yetkin yok.", status: :forbidden)
    false
  end

  def render_error(code:, message:, status:, fields: {})
    render json: { error: { code: code, message: message, fields: fields } }, status: status
  end

  def render_validation_error(record)
    render_error(
      code: "validation_failed",
      message: record.errors.full_messages.first || "Geçersiz veri.",
      status: :unprocessable_entity,
      fields: record.errors.to_hash,
    )
  end

  def paginate(relation)
    page = [params[:page].to_i, 1].max
    per_page =
      if params[:per_page].present?
        [[params[:per_page].to_i, 1].max, 50].min
      else
        20
      end

    total = relation.count
    total_pages = (total.to_f / per_page).ceil
    data = relation.offset((page - 1) * per_page).limit(per_page)

    [data, { page: page, per_page: per_page, total: total, total_pages: total_pages }]
  end

  def render_not_found
    render_error(code: "not_found", message: "Kayıt bulunamadı.", status: :not_found)
  end

  def render_bad_request(exception)
    render_error(code: "bad_request", message: exception.message, status: :bad_request)
  end
end
