Sequel.migration do
  change do
    create_table(:threepid_guest_access_tokens) do
      Text :medium
      Text :address
      Text :guest_access_token
      Text :first_inviter

      unique [:medium, :address]
    end
  end
end
