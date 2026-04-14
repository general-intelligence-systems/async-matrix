Sequel.migration do
  change do
    create_table(:user_filters) do
      Text :user_id, null: false
      Bignum :filter_id, null: false
      File :filter_json, null: false

      unique [:user_id, :filter_id]
    end
  end
end
