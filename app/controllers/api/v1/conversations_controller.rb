module Api
  module V1
    class ConversationsController < ApplicationController
      before_action :require_user!

      def index
        conversations = current_user_conversations
          .ordered
          .includes(:buyer, listing: [:user, :part, { photos_attachments: :blob }])

        render json: ConversationSerializer.list_items(conversations, current_user)
      end

      def create
        listing = Listing.find(params[:listing_id])

        if listing.owner?(current_user)
          render_error(
            code: "own_listing",
            message: "Kendi ilanına mesaj atamazsın.",
            status: :unprocessable_entity,
          )
          return
        end

        unless listing.active?
          render_error(
            code: "listing_not_active",
            message: "Bu ilana mesaj atılamaz.",
            status: :unprocessable_entity,
          )
          return
        end

        body = params[:body].to_s.strip.presence
        if body && body.length > 1000
          render_error(
            code: "validation_failed",
            message: "Mesaj en fazla 1000 karakter olabilir.",
            status: :unprocessable_entity,
            fields: { body: ["en fazla 1000 karakter"] },
          )
          return
        end

        conversation = Conversation.find_or_initialize_by(listing: listing, buyer: current_user)
        is_new = conversation.new_record?
        conversation.messages.build(sender: current_user, body: body) if body

        if conversation.save
          render json: ConversationSerializer.detail(conversation, current_user),
            status: is_new ? :created : :ok
        else
          render_validation_error(conversation)
        end
      end

      def show
        conversation = load_conversation
        return if conversation.nil?

        conversation.mark_read_for(current_user)
        messages = load_messages(conversation, params[:before])

        render json: {
          conversation: ConversationSerializer.detail(conversation, current_user),
          messages: messages.map { |m| MessageSerializer.render(m) },
        }
      end

      def messages
        conversation = load_conversation
        return if conversation.nil?

        after = params[:after].to_i
        scope = conversation.messages.order(id: :asc)
        scope = scope.where("id > ?", after) if after.positive?

        messages = scope.to_a
        conversation.mark_read_for(current_user) if messages.any?

        render json: { messages: messages.map { |m| MessageSerializer.render(m) } }
      end

      def create_message
        conversation = load_conversation
        return if conversation.nil?

        body = params[:body].to_s.strip
        if body.blank?
          render_error(
            code: "validation_failed",
            message: "Mesaj boş olamaz.",
            status: :unprocessable_entity,
            fields: { body: ["boş olamaz"] },
          )
          return
        end

        if body.length > 1000
          render_error(
            code: "validation_failed",
            message: "Mesaj en fazla 1000 karakter olabilir.",
            status: :unprocessable_entity,
            fields: { body: ["en fazla 1000 karakter"] },
          )
          return
        end

        message = conversation.messages.build(sender: current_user, body: body)

        if message.save
          render json: MessageSerializer.render(message), status: :created
        else
          render_validation_error(message)
        end
      end

      private

      def current_user_conversations
        Conversation.left_joins(:listing).where(
          "conversations.buyer_id = :id OR listings.user_id = :id",
          id: current_user.id,
        )
      end

      def load_conversation
        conversation = Conversation.find_by(id: params[:id])
        if conversation.nil? || !conversation.participant?(current_user)
          render_not_found
          return nil
        end

        conversation
      end

      def load_messages(conversation, before)
        scope = conversation.messages.order(id: :desc)
        scope = scope.where("id < ?", before.to_i) if before.present? && before.to_i.positive?

        scope.limit(50).to_a.reverse
      end
    end
  end
end
