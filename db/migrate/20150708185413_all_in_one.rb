class AllInOne < ActiveRecord::Migration
  def change
    
    create_table "smartrent_articles" do |t|
      t.string   "title"
      t.text     "text"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    create_table "smartrent_contacts" do |t|
      t.string   "name"
      t.string   "email"
      t.text     "message"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    create_table "smartrent_features" do |t|
      t.string   "name"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    create_table "smartrent_floor_plan_images" do |t|
      t.string   "image_file_name"
      t.string   "image_content_type"
      t.integer  "image_file_size"
      t.datetime "image_updated_at"
      t.string   "caption"
      t.integer  "more_home_id"
      t.datetime "created_at",         :null => false
      t.datetime "updated_at",         :null => false
    end

    create_table "smartrent_floor_plans" do |t|
      t.integer  "property_id"
      t.integer  "origin_id"
      t.string   "name"
      t.string   "url"
      t.float    "sq_feet_max"
      t.float    "sq_feet_min"
      t.integer  "beds"
      t.integer  "baths"
      t.integer  "rent_min"
      t.integer  "rent_max"
      t.boolean  "penthouse"
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false
    end

    create_table "smartrent_homes" do |t|
      t.string   "title"
      t.text     "address"
      t.string   "website"
      t.text     "description"
      t.float    "latitude"
      t.float    "longitude"
      t.datetime "created_at",              :null => false
      t.datetime "updated_at",              :null => false
      t.string   "url"
      t.string   "phone_number"
      t.string   "video_url"
      t.text     "home_page_desc"
      t.string   "city"
      t.string   "state"
      t.string   "postal_code"
      t.string   "image_file_name"
      t.string   "image_content_type"
      t.integer  "image_file_size"
      t.datetime "image_updated_at"
      t.string   "image_description"
      t.text     "search_page_description"
    end

    create_table "smartrent_more_homes" do |t|
      t.string   "name"
      t.integer  "beds"
      t.float    "baths"
      t.float    "sq_ft"
      t.boolean  "featured"
      t.integer  "home_id"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    create_table "smartrent_properties" do |t|
      t.string   "title"
      t.string   "phone_number"
      t.string   "website"
      t.string   "short_description"
      t.string   "state"
      t.string   "county"
      t.string   "city"
      t.string   "address"
      t.float    "latitude",                  :default => 0.0
      t.float    "longitude",                 :default => 0.0
      t.float    "studio_price",              :default => 0.0
      t.boolean  "special_promotion",         :default => false
      t.datetime "created_at",                                   :null => false
      t.datetime "updated_at",                                   :null => false
      t.string   "image_file_name"
      t.string   "image_content_type"
      t.integer  "image_file_size"
      t.datetime "image_updated_at"
      t.boolean  "studio",                    :default => false
      t.integer  "origin_id"
      t.string   "bozzuto_url"
      t.string   "email"
      t.string   "promotion_title"
      t.string   "promotion_subtitle"
      t.string   "promotion_url"
      t.date     "promotion_expiration_date"
      t.string   "zip"
      t.text     "description"
      t.integer  "status",                    :default => 1
    end

    create_table "smartrent_property_features" do |t|
      t.integer  "feature_id"
      t.integer  "property_id"
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false
    end

    create_table "smartrent_residents" do |t|
      t.string   "email",                               :default => "",   :null => false
      t.string   "encrypted_password",                  :default => "",   :null => false
      t.string   "reset_password_token"
      t.datetime "reset_password_sent_at"
      t.datetime "remember_created_at"
      t.integer  "sign_in_count",                       :default => 0,    :null => false
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string   "current_sign_in_ip"
      t.string   "last_sign_in_ip"
      t.datetime "created_at",                                            :null => false
      t.datetime "updated_at",                                            :null => false
      t.string   "confirmation_token"
      t.datetime "confirmed_at"
      t.datetime "confirmation_sent_at"
      t.integer  "failed_attempts",                     :default => 0,    :null => false
      t.string   "unlock_token"
      t.datetime "locked_at"
      t.string   "name"
      t.string   "home_phone"
      t.string   "work_phone"
      t.string   "cell_phone"
      t.string   "company"
      t.integer  "house_hold_size"
      t.integer  "pets_count"
      t.datetime "contract_signing_date"
      t.integer  "type_"
      t.integer  "status"
      t.date     "move_in_date"
      t.date     "move_out_date"
      t.string   "address"
      t.string   "city"
      t.string   "state"
      t.string   "zip"
      t.string   "current_community"
      t.boolean  "active",                              :default => true
      t.string   "country"
      t.integer  "origin_id"
      t.integer  "property_id"
      t.integer  "home_id"
    end

    add_index "smartrent_residents", ["email"], :name => "index_smartrent_residents_on_email", :unique => true
    add_index "smartrent_residents", ["reset_password_token"], :name => "index_smartrent_residents_on_reset_password_token", :unique => true

    create_table "smartrent_rewards" do |t|
      t.integer  "resident_id"
      t.integer  "type_"
      t.integer  "property_id"
      t.datetime "period_start"
      t.datetime "period_end"
      t.float    "amount"
      t.string   "rule_applied"
      t.datetime "created_at",   :null => false
      t.datetime "updated_at",   :null => false
    end

    create_table "smartrent_settings" do |t|
      t.string   "key"
      t.string   "value"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    create_table "smartrent_users" do |t|
      t.string   "email",                  :default => "", :null => false
      t.string   "encrypted_password",     :default => "", :null => false
      t.string   "reset_password_token"
      t.datetime "reset_password_sent_at"
      t.datetime "remember_created_at"
      t.integer  "sign_in_count",          :default => 0,  :null => false
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string   "current_sign_in_ip"
      t.string   "last_sign_in_ip"
      t.datetime "created_at",                             :null => false
      t.datetime "updated_at",                             :null => false
      t.string   "confirmation_token"
      t.datetime "confirmed_at"
      t.datetime "confirmation_sent_at"
      t.integer  "failed_attempts",        :default => 0,  :null => false
      t.string   "unlock_token"
      t.datetime "locked_at"
      t.string   "name"
      t.string   "address"
      t.string   "city"
      t.string   "state"
      t.string   "zip"
    end

    add_index "smartrent_users", ["email"], :name => "index_smartrent_users_on_email", :unique => true
    add_index "smartrent_users", ["reset_password_token"], :name => "index_smartrent_users_on_reset_password_token", :unique => true

    
  end
end
