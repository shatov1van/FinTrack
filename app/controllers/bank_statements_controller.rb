class BankStatementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_statement, only: %i[reparse choose_bank archive destroy]

  def index
    @bank_statements = current_user.bank_statements.order(created_at: :desc)
  end

  def choose_bank
    @statement.update!(bank_name: params[:bank_name], status: "pending", error_message: nil)
    ParseStatementJob.perform_later(@statement)
    redirect_to bank_statements_path, notice: "Выписка поставлена на повторный парсинг."
  end

  def reparse
    @statement.update!(status: "pending", error_message: nil, imported_count: 0, duplicate_count: 0)
    ParseStatementJob.perform_later(@statement)
    redirect_to bank_statements_path, notice: "Повторный парсинг запущен."
  end

  def archive
    @statement.update!(archived: true)
    redirect_to bank_statements_path, notice: "Выписка архивирована."
  end

  def destroy
    @statement.destroy!
    redirect_to bank_statements_path, notice: "Выписка удалена."
  end

  private

  def set_statement
    @statement = current_user.bank_statements.find(params[:id])
  end
end
