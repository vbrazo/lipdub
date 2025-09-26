# frozen_string_literal: true

RSpec.describe Lipdub::Configuration do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.base_url).to eq("https://api.lipdub.ai")
      expect(config.timeout).to eq(30)
      expect(config.open_timeout).to eq(10)
      expect(config.api_key).to be_nil
    end
  end

  describe "#valid?" do
    context "when api_key is nil" do
      it "returns false" do
        config.api_key = nil
        expect(config.valid?).to be false
      end
    end

    context "when api_key is empty string" do
      it "returns false" do
        config.api_key = ""
        expect(config.valid?).to be false
      end
    end

    context "when api_key is present" do
      it "returns true" do
        config.api_key = "test_key"
        expect(config.valid?).to be true
      end
    end
  end
end
