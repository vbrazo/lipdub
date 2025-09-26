# frozen_string_literal: true

RSpec.describe Lipdub do
  it "has a version number" do
    expect(Lipdub::VERSION).not_to be nil
  end

  describe ".configure" do
    it "yields the configuration" do
      expect { |b| Lipdub.configure(&b) }.to yield_with_args(Lipdub.configuration)
    end

    it "allows setting configuration values" do
      Lipdub.configure do |config|
        config.api_key = "test_key"
        config.base_url = "https://custom.api.url"
        config.timeout = 60
      end

      expect(Lipdub.configuration.api_key).to eq("test_key")
      expect(Lipdub.configuration.base_url).to eq("https://custom.api.url")
      expect(Lipdub.configuration.timeout).to eq(60)
    end
  end

  describe ".client" do
    before do
      Lipdub.configure do |config|
        config.api_key = "test_api_key"
      end
    end

    it "returns a client instance" do
      expect(Lipdub.client).to be_a(Lipdub::Client)
    end

    it "reuses the same client instance" do
      client1 = Lipdub.client
      client2 = Lipdub.client
      expect(client1).to be(client2)
    end
  end
end
