class CreateActiveStorageTables < ActiveRecord::Migration[8.1]
  def change
    create_table :active_storage_blobs unless table_exists?(:active_storage_blobs)
    if table_exists?(:active_storage_blobs) && !column_exists?(:active_storage_blobs, :key)
      add_column :active_storage_blobs, :key, :string, null: false
      add_column :active_storage_blobs, :filename, :string, null: false
      add_column :active_storage_blobs, :content_type, :string
      add_column :active_storage_blobs, :metadata, :text
      add_column :active_storage_blobs, :service_name, :string, null: false
      add_column :active_storage_blobs, :byte_size, :bigint, null: false
      add_column :active_storage_blobs, :checksum, :string, null: false
      add_column :active_storage_blobs, :created_at, :datetime, null: false
      add_index :active_storage_blobs, :key, unique: true
    end

    create_table :active_storage_attachments unless table_exists?(:active_storage_attachments)
    if table_exists?(:active_storage_attachments) && !column_exists?(:active_storage_attachments, :name)
      add_column :active_storage_attachments, :name, :string, null: false
      add_column :active_storage_attachments, :record_type, :string, null: false
      add_column :active_storage_attachments, :record_id, :bigint, null: false
      add_column :active_storage_attachments, :blob_id, :bigint, null: false
      add_column :active_storage_attachments, :created_at, :datetime, null: false
      add_index :active_storage_attachments, %i[record_type record_id name blob_id], unique: true, name: "index_active_storage_attachments_uniqueness"
      add_index :active_storage_attachments, %i[record_type record_id name], name: "index_active_storage_attachments_lookup"
      add_foreign_key :active_storage_attachments, :active_storage_blobs, column: :blob_id
    end
  end
end
