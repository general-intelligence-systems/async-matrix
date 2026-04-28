# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module ApplicationService
      class Config
        # Mixin that gives a Hash dot-notation accessors with autovivification.
        #
        # Not applied globally — only extended onto the validated config hash
        # and its nested children so the rest of the world is unaffected.
        #
        #   h = {}.extend(Vivify)
        #   h.foo.bar.baz = 42
        #   h  # => { foo: { bar: { baz: 42 } } }
        #
        module Vivify
          def method_missing(name, *args)
            key = name.to_s

            if key.end_with?("=")
              self[key.chomp("=").to_sym] = args.first
            elsif key?(name.to_sym)
              self[name.to_sym]
            elsif key.start_with?("to_")
              super
            else
              self[name.to_sym] = {}.extend(Vivify)
            end
          end

          def respond_to_missing?(name, _priv = false)
            name.to_s.end_with?("=") || key?(name.to_sym) || super
          end

          # Recursively symbolize keys and extend every nested Hash with Vivify.
          #
          # Call this on the raw (string-keyed) hash that comes out of
          # YAML.safe_load / JSON Schema validation before wrapping it in Config.
          def self.deep_vivify(obj)
            case obj
            when Hash
              result = {}
              obj.each { |k, v| result[k.to_s.to_sym] = deep_vivify(v) }
              result.extend(Vivify)
            when Array
              obj.map { |v| deep_vivify(v) }
            else
              obj
            end
          end
        end
      end
    end
  end
end

test do
  V = Async::Matrix::ApplicationService::Config::Vivify

  describe "Vivify" do
    it "provides dot-notation read access to symbol keys" do
      h = { foo: "bar" }.extend(V)
      h.foo.should == "bar"
    end

    it "provides dot-notation write access" do
      h = {}.extend(V)
      h.foo = 42
      h[:foo].should == 42
    end

    it "autovivifies missing keys as vivified hashes" do
      h = {}.extend(V)
      h.a.b.c = "deep"
      h[:a][:b][:c].should == "deep"
    end

    it "delegates to_* methods to super (no autovivify)" do
      h = { x: 1 }.extend(V)
      h.to_a.should == [[:x, 1]]
    end
  end

  describe "Vivify.deep_vivify" do
    it "symbolizes string keys" do
      result = V.deep_vivify({"a" => 1})
      result[:a].should == 1
    end

    it "recursively vivifies nested hashes" do
      result = V.deep_vivify({"outer" => {"inner" => "val"}})
      result.outer.inner.should == "val"
    end

    it "vivifies hashes inside arrays" do
      result = V.deep_vivify({"list" => [{"name" => "x"}]})
      result.list.first.name.should == "x"
    end

    it "passes scalars through unchanged" do
      result = V.deep_vivify({"n" => 42, "s" => "hi", "b" => true})
      result.n.should == 42
      result.s.should == "hi"
      result.b.should == true
    end
  end
end
