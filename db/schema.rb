# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090226025133) do

  create_table "answers", :force => true do |t|
    t.text     "answer_text"
    t.integer  "question_id", :limit => 11
    t.integer  "user_id",     :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "books", :force => true do |t|
    t.string   "name"
    t.integer  "questions_count", :limit => 11
    t.integer  "is_public",       :limit => 11
    t.integer  "user_id",         :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "outline"
  end

  create_table "categories", :force => true do |t|
    t.string   "name",       :limit => 64
    t.integer  "user_id",    :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "descriptions", :force => true do |t|
    t.text     "description_text"
    t.integer  "question_id",      :limit => 11
    t.integer  "user_id",          :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "evaluations", :force => true do |t|
    t.integer  "question_id", :limit => 11, :null => false
    t.integer  "user_id",     :limit => 11, :null => false
    t.integer  "point",       :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "exam_temps", :force => true do |t|
    t.integer  "exam_id",     :limit => 11
    t.integer  "question_id", :limit => 11
    t.string   "answer"
    t.string   "status"
    t.boolean  "t_or_f"
    t.integer  "user_id",     :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "exams", :force => true do |t|
    t.string   "name"
    t.integer  "questions_count", :limit => 11
    t.integer  "time_limit",      :limit => 11
    t.integer  "border_line",     :limit => 11
    t.integer  "is_public",       :limit => 11
    t.integer  "user_id",         :limit => 11
    t.integer  "book_id",         :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "notes"
  end

  create_table "histories", :force => true do |t|
    t.integer  "user_id",          :limit => 11
    t.integer  "question_id",      :limit => 11
    t.boolean  "correct_or_wrong"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "my_books", :force => true do |t|
    t.integer  "user_id",    :limit => 11, :null => false
    t.integer  "book_id",    :limit => 11, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "my_exams", :force => true do |t|
    t.integer  "user_id",    :limit => 11, :null => false
    t.integer  "exam_id",    :limit => 11, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "question_books", :force => true do |t|
    t.integer  "book_id",     :limit => 11, :null => false
    t.integer  "question_id", :limit => 11, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "question_exams", :force => true do |t|
    t.integer  "exam_id",     :limit => 11, :null => false
    t.integer  "question_id", :limit => 11, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "seq",         :limit => 11
    t.boolean  "enabled"
  end

  create_table "question_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "questions", :force => true do |t|
    t.integer  "question_type",    :limit => 11
    t.text     "question_text"
    t.integer  "selections_count", :limit => 11
    t.integer  "is_public",        :limit => 11
    t.integer  "user_id",          :limit => 11
    t.integer  "category_id",      :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "question_count",   :limit => 11, :default => 0
    t.integer  "correct_count",    :limit => 11, :default => 0
    t.integer  "wrong_count",      :limit => 11, :default => 0
    t.boolean  "y_or_n"
    t.boolean  "is_random"
  end

  create_table "reports", :force => true do |t|
    t.integer  "user_id",     :limit => 11, :null => false
    t.integer  "question_id", :limit => 11, :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "selections", :force => true do |t|
    t.text     "selection_text"
    t.integer  "is_collect",     :limit => 11
    t.integer  "question_id",    :limit => 11
    t.integer  "user_id",        :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id",        :limit => 11
    t.integer  "taggable_id",   :limit => 11
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
  end

end
