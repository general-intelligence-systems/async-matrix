# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "schema"

module Async
  module Matrix
    module Bridge
      module Discord
        module DB
          # Caches uploaded media to avoid re-uploading the same Discord
          # attachment to the Matrix homeserver.
          #
          # Uses a composite primary key of (url, encrypted) because the same
          # source URL may be uploaded both encrypted and unencrypted to
          # different portal rooms.
          #
          #   cached = CachedFile.create(
          #     url: "https://cdn.discordapp.com/...",
          #     encrypted: false,
          #     mxc: "mxc://example.com/abc"
          #   )
          #
          class CachedFile < Sequel::Model
            unrestrict_primary_key

            def validate
              super
              errors.add(:url, "cannot be empty") if url.nil? || url.empty?
              errors.add(:mxc, "cannot be empty") if mxc.nil? || mxc.empty?
            end

            # Look up a cached file by source URL and encryption status.
            def self.by_url(url, encrypted: false)
              first(url: url, encrypted: encrypted)
            end
          end
        end
      end
    end
  end
end

__END__
  describe "Async::Matrix::Bridge::Discord::DB::CachedFile" do
    def setup_db
      db = Sequel.sqlite
      Sequel::Migrator.run(db, File.join(__dir__, "migrations"))
      db
    end

    it "creates and retrieves a cached file" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::CachedFile.dataset = db[:files]

      cached = Async::Matrix::Bridge::Discord::DB::CachedFile.create(
        url: "https://cdn.discordapp.com/attachments/123/456/image.png",
        mxc: "mxc://example.com/abc",
        mime_type: "image/png",
        size: 102400,
        width: 800,
        height: 600
      )
      cached.url.should.include "discordapp.com"
      cached.mxc.should == "mxc://example.com/abc"
      cached.mime_type.should == "image/png"
      cached.width.should == 800
      cached.height.should == 600
      db.disconnect
    end

    it "looks up by URL and encryption status" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::CachedFile.dataset = db[:files]

      Async::Matrix::Bridge::Discord::DB::CachedFile.create(
        url: "https://example.com/file.png", encrypted: false,
        mxc: "mxc://x/plain"
      )
      Async::Matrix::Bridge::Discord::DB::CachedFile.create(
        url: "https://example.com/file.png", encrypted: true,
        mxc: "mxc://x/encrypted",
        decryption_info: '{"key":"abc"}'
      )

      plain = Async::Matrix::Bridge::Discord::DB::CachedFile.by_url("https://example.com/file.png")
      plain.mxc.should == "mxc://x/plain"

      enc = Async::Matrix::Bridge::Discord::DB::CachedFile.by_url("https://example.com/file.png", encrypted: true)
      enc.mxc.should == "mxc://x/encrypted"
      enc.decryption_info.should == '{"key":"abc"}'
      db.disconnect
    end

    it "defaults encrypted to false" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::CachedFile.dataset = db[:files]

      cached = Async::Matrix::Bridge::Discord::DB::CachedFile.create(
        url: "https://example.com/a.jpg", mxc: "mxc://x/y"
      )
      cached.encrypted.should == false
      db.disconnect
    end

    it "validates required fields" do
      db = setup_db
      Async::Matrix::Bridge::Discord::DB::CachedFile.dataset = db[:files]

      f = Async::Matrix::Bridge::Discord::DB::CachedFile.new(url: "", mxc: "")
      f.valid?.should == false
      f.errors[:url].should.not.be.empty
      f.errors[:mxc].should.not.be.empty
      db.disconnect
    end
  end
