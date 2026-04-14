class Event < Sequel::Model(:events)
  unrestrict_primary_key
  set_primary_key :event_id

  many_to_one :room, key: :room_id
  one_to_one :current_state_event, key: :event_id
  one_to_one :batch_event, class: :BatchEvent, key: :event_id

  dataset_module do
    def non_outliers
      where(outlier: false)
    end

    def with_urls
      where(contains_url: true)
    end
  end
end
