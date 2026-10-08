module Api
  module V1
    module Forum
      class BoardsController < BaseController
        def index
          render json: ForumBoard.ordered.map { |board| ForumBoardSerializer.render(board) }
        end

        def show
          board = ForumBoard.find_by(slug: params[:slug])
          return render_not_found unless board

          render json: ForumBoardSerializer.render(board)
        end
      end
    end
  end
end
