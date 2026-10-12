# frozen_string_literal: true

require "sequel/model"

require_relative "typecasting"

module Models
  module Matrix
    # One entry in an Application Service's interested-in namespaces: a POSIX regex
    # and whether the AS claims it exclusively. `kind` picks which of the three
    # registration lists it belongs to (users / aliases / rooms). See
    # https://spec.matrix.org/latest/application-service-api/#registration.
    class AppServiceNamespace < Sequel::Model(:matrix_app_service_namespaces)
      # Rails had `enum :kind, { users: "users", ... }, validate: true`, which gave
      # the class a `.kinds` hash that AppService#registration_namespaces reads.
      # Sequel has no enum, so the hash is the constant and the validation is
      # validates_includes -- the call site keeps working unchanged.
      KINDS = { "users" => "users", "aliases" => "aliases", "rooms" => "rooms" }.freeze

      # Association name (and so the `matrix_app_service_id` column) predates the
      # move under Matrix::, hence the explicit class_name — the name would
      # otherwise infer a Matrix::MatrixAppService that doesn't exist.
      many_to_one :matrix_app_service, class: "Models::Matrix::AppService"

      plugin :timestamps, update_on_create: true
      plugin :validation_helpers

      extend Typecasting

      def self.kinds = KINDS

      def validate
        super
        validates_presence :regex
        validates_includes KINDS.keys, :kind
      end

      # DROPPED IN THE PORT: `after_commit :enqueue_sync`, which called
      # MatrixEngine.app_service_sync_callback to rewrite Synapse's aggregate
      # `synapse-appservices` Secret and roll the StatefulSet. That reconciliation
      # belongs to the Rails app -- it is the thing holding the Kubernetes client
      # and the callback -- and nothing here should be writing cluster Secrets
      # behind a model save. If the controller ever registers its own appservice,
      # that is a deliberate step, not a side effect of an INSERT.
    end
  end
end

__END__

create_table?(:matrix_app_service_namespaces) do
  primary_key :id, type: :Bignum, serial: true
  column      :created_at, TIMESTAMP, null: false
  column      :exclusive, :boolean, default: false, null: false
  column      :kind, TEXT, null: false
  # The constraint NAME is Rails' too: it derives
  # fk_rails_<sha256("<table>_<column>_fk")[0,10]> and schema.rb does not
  # print it, so it is spelled out here rather than left to Sequel's
  # own <table>_<column>_fkey convention.
  foreign_key :matrix_app_service_id,
    :matrix_app_services,
    type:                        :Bignum,
    null:                        false,
    foreign_key_constraint_name: :fk_rails_590f4c3c13
  column      :regex, TEXT, null: false
  column      :updated_at, TIMESTAMP, null: false

  index %i[matrix_app_service_id kind],
    name: :idx_on_matrix_app_service_id_kind_0aa44c20ab
  index :matrix_app_service_id,
    name: :index_matrix_app_service_namespaces_on_matrix_app_service_id
end
