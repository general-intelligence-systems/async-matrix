class Room < Sequel::Model(:rooms)
  unrestrict_primary_key
  set_primary_key :room_id

  one_to_many :events, key: :room_id
  one_to_many :current_state_events, key: :room_id
  one_to_many :destination_rooms, key: :room_id
  one_to_many :batch_events, key: :room_id

  dataset_module do
    def public_rooms
      where(is_public: true)
    end
  end
end
