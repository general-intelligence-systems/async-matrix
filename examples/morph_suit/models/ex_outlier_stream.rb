class ExOutlierStream < Sequel::Model(:ex_outlier_stream)
  unrestrict_primary_key
  set_primary_key :event_stream_ordering
end
