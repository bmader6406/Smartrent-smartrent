class AllInOne < ActiveRecord::Migration
  def change
    create_table "smartrent_articles" do |t|
      t.string   "title",      limit: 255
      t.text     "text",       limit: 65535
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "smartrent_contacts" do |t|
      t.string   "name",       limit: 255
      t.string   "email",      limit: 255
      t.text     "message",    limit: 65535
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "smartrent_features" do |t|
      t.string   "name",       limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "smartrent_floor_plan_images" do |t|
      t.string   "caption",            limit: 255
      t.integer  "more_home_id",       limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "image_file_name",    limit: 255
      t.string   "image_content_type", limit: 255
      t.integer  "image_file_size",    limit: 4
      t.datetime "image_updated_at"
    end

    create_table "smartrent_floor_plans" do |t|
      t.integer  "property_id", limit: 4
      t.integer  "origin_id",   limit: 4
      t.string   "name",        limit: 255
      t.string   "url",         limit: 255
      t.float    "sq_feet_max", limit: 24
      t.float    "sq_feet_min", limit: 24
      t.integer  "beds",        limit: 4
      t.integer  "baths",       limit: 4
      t.integer  "rent_min",    limit: 4
      t.integer  "rent_max",    limit: 4
      t.boolean  "penthouse",   limit: 1
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "smartrent_homes" do |t|
      t.string   "title",                   limit: 255
      t.text     "address",                 limit: 65535
      t.string   "website",                 limit: 255
      t.text     "description",             limit: 65535
      t.float    "latitude",                limit: 24
      t.float    "longitude",               limit: 24
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "phone_number",            limit: 255
      t.string   "video_url",               limit: 255
      t.text     "home_page_desc",          limit: 65535
      t.string   "city",                    limit: 255
      t.string   "state",                   limit: 255
      t.string   "postal_code",             limit: 255
      t.string   "image_file_name",         limit: 255
      t.string   "image_content_type",      limit: 255
      t.integer  "image_file_size",         limit: 4
      t.datetime "image_updated_at"
      t.string   "image_description",       limit: 255
      t.text     "search_page_description", limit: 65535
    end

    create_table "smartrent_more_homes" do |t|
      t.string   "name",       limit: 255
      t.integer  "beds",       limit: 4
      t.float    "baths",      limit: 24
      t.float    "sq_ft",      limit: 24
      t.boolean  "featured",   limit: 1
      t.integer  "home_id",    limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "smartrent_properties" do |t|
      t.string   "title",                     limit: 255
      t.string   "phone_number",              limit: 255
      t.string   "website",                   limit: 255
      t.string   "short_description",         limit: 255
      t.string   "state",                     limit: 255
      t.string   "county",                    limit: 255
      t.string   "city",                      limit: 255
      t.string   "address",                   limit: 255
      t.float    "latitude",                  limit: 24,    default: 0.0
      t.float    "longitude",                 limit: 24,    default: 0.0
      t.float    "studio_price",              limit: 24,    default: 0.0
      t.boolean  "special_promotion",         limit: 1,     default: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "image_file_name",           limit: 255
      t.string   "image_content_type",        limit: 255
      t.integer  "image_file_size",           limit: 4
      t.datetime "image_updated_at"
      t.boolean  "studio",                    limit: 1,     default: false
      t.integer  "origin_id",                 limit: 4
      t.string   "bozzuto_url",               limit: 255
      t.string   "email",                     limit: 255
      t.string   "promotion_title",           limit: 255
      t.string   "promotion_subtitle",        limit: 255
      t.string   "promotion_url",             limit: 255
      t.date     "promotion_expiration_date"
      t.string   "zip",                       limit: 255
      t.text     "description",               limit: 65535
      t.integer  "status",                    limit: 4,     default: 1
    end

    create_table "smartrent_property_features" do |t|
      t.integer  "feature_id",  limit: 4
      t.integer  "property_id", limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table(:smartrent_residents) do |t|
      ## Database authenticatable
      t.string :first_name
      t.string :last_name
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at


      t.timestamps
    end

    add_index :smartrent_residents, :email,                unique: true
    add_index :smartrent_residents, :reset_password_token, unique: true
    # add_index :smartrent_residents, :confirmation_token,   unique: true
    # add_index :smartrent_residents, :unlock_token,         unique: true

    create_table "smartrent_rewards" do |t|
      t.integer  "resident_id",   limit: 4
      t.integer  "type_",         limit: 4
      t.integer  "property_id",   limit: 4
      t.datetime "period_start"
      t.datetime "period_end"
      t.float    "amount",        limit: 24
      t.string   "rules_applied", limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "smartrent_settings" do |t|
      t.string   "key",        limit: 255
      t.string   "value",      limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table(:smartrent_users) do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at


      t.timestamps
    end

    add_index :smartrent_users, :email,                unique: true
    add_index :smartrent_users, :reset_password_token, unique: true
    # add_index :smartrent_users, :confirmation_token,   unique: true
    # add_index :smartrent_users, :unlock_token,         unique: true
    
  end
end
