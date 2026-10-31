class ScopeStatementDigestToUser < ActiveRecord::Migration[8.1]
  def change
    remove_index :bank_statements, :file_digest, unique: true if index_exists?(:bank_statements, :file_digest, unique: true)
    add_index :bank_statements, %i[user_id file_digest], unique: true unless index_exists?(:bank_statements, %i[user_id file_digest], unique: true)
  end
end
