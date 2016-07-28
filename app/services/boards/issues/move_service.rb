module Boards
  module Issues
    class MoveService
      def initialize(project, user, params = {})
        @project = project
        @user = user
        @params = params.dup
      end

      def execute
        return false unless issue.present?

        update_service.execute(issue)
        reopen_service.execute(issue) if moving_from.done?
        close_service.execute(issue)  if moving_to.done?

        true
      end

      private

      attr_reader :project, :user, :params

      delegate :board, to: :project

      def issue
        @issue ||= project.issues.visible_to_user(user).find_by!(iid: params[:id])
      end

      def moving_from
        @moving_from ||= board.lists.find(params[:from])
      end

      def moving_to
        @moving_to ||= board.lists.find(params[:to])
      end

      def close_service
        ::Issues::CloseService.new(project, user)
      end

      def reopen_service
        ::Issues::ReopenService.new(project, user)
      end

      def update_service
        ::Issues::UpdateService.new(project, user, issue_params)
      end

      def issue_params
        {
          add_label_ids: [moving_to.label_id].compact,
          remove_label_ids: [moving_from.label_id].compact
        }
      end
    end
  end
end
