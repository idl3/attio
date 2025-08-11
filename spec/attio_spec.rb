RSpec.describe Attio do
  it "has a version number" do
    expect(Attio::VERSION).not_to be nil
  end

  describe ".client" do
    it "creates a new client instance" do
      client = described_class.client(api_key: "test_key")
      expect(client).to be_a(Attio::Client)
      expect(client.api_key).to eq("test_key")
    end

    it "creates different client instances for different API keys" do
      client1 = described_class.client(api_key: "key1")
      client2 = described_class.client(api_key: "key2")
      
      expect(client1).not_to eq(client2)
      expect(client1.api_key).to eq("key1")
      expect(client2.api_key).to eq("key2")
    end
  end
end