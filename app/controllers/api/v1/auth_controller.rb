module Api
  module V1
    class AuthController < ApplicationController
      def register
        user = User.new(register_params)

        if user.save
          session[:user_id] = user.id
          render json: UserSerializer.render(user, include_phone: true), status: :created
        else
          render_validation_error(user)
        end
      end

      def login
        user = User.find_by(email: params[:email].to_s.strip.downcase)

        if user&.authenticate(params[:password].to_s)
          session[:user_id] = user.id
          render json: UserSerializer.render(user, include_phone: true)
        else
          render_error(
            code: "invalid_credentials",
            message: "E-posta ya da şifre tutmadı. Bir daha dene.",
            status: :unauthorized,
          )
        end
      end

      def logout
        reset_session
        head :no_content
      end

      private

      def register_params
        params.permit(:full_name, :email, :password, :city)
      end
    end
  end
end
