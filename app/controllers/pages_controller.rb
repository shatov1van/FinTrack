class PagesController < ApplicationController
  before_action :authenticate_user!, only: :import

  def home
    return unless user_signed_in?

    @user = current_user
    @recent_transactions = @user.financial_transactions.includes(:category).order(transaction_date: :desc).limit(10)
  end

  def import
    return unless request.post?

    StatementImporter.call(user: current_user, uploaded_file: params[:statement_file])
    redirect_to import_path, notice: "Выписка успешно импортирована."
  rescue StatementImporter::Error => e
    redirect_to import_path, alert: e.message
  end
end
