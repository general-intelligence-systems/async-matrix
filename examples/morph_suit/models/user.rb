class User < Sequel::Model(:users)
  unrestrict_primary_key
  set_primary_key :name

  one_to_many :access_tokens, key: :user_id
  one_to_many :refresh_tokens, key: :user_id
  one_to_many :devices, key: :user_id
  one_to_one :account_validity, key: :user_id
  one_to_many :account_data, key: :user_id
  one_to_one :dehydrated_device, key: :user_id

  dataset_module do
    def active
      where(deactivated: 0)
    end

    def admins
      where(admin: 1)
    end

    def guests
      where(is_guest: 1)
    end
  end
end
