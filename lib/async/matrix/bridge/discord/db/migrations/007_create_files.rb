# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:files) do
      String :url, null: false
      TrueClass :encrypted, null: false, default: false
      String :mxc, null: false
      String :mime_type
      Bignum :size
      Integer :width
      Integer :height
      String :decryption_info

      primary_key [:url, :encrypted]
    end
  end
end
