# frozen_string_literal: true

get "/" do
  content_type(:json)
  MultiJson.dump(up: true)
end
