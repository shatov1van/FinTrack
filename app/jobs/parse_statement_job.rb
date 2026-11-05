class ParseStatementJob < ApplicationJob
  queue_as :default

  def perform(statement)
    statement.source_file.open do |file|
      upload = ActionDispatch::Http::UploadedFile.new(
        filename: statement.file_name,
        type: statement.source_file.content_type,
        tempfile: file
      )
      StatementImporter.new(user: statement.user, uploaded_file: upload, statement:).process
    end
  rescue StatementImporter::Error => e
    statement.update!(status: "error", error_message: e.message)
  rescue StandardError => e
    statement.update!(status: "error", error_message: "Не удалось обработать файл: #{e.message}")
  end
end
