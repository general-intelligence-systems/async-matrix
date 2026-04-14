Sequel.migration do
  change do
    create_table(:user_threepids) do
      Text :user_id, null: false
      Text :medium, null: false
      Text :address, null: false
      Bignum :validated_at, null: false
      Bignum :added_at, null: false

      unique [:medium, :address]
      index :user_id
    end
  end
end
