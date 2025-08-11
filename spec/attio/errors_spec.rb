# frozen_string_literal: true

RSpec.describe "Attio Errors" do
  describe Attio::Error do
    it "is a StandardError" do
      expect(described_class.superclass).to eq(StandardError)
    end
  end

  describe Attio::AuthenticationError do
    it "is an Attio::Error" do
      expect(described_class.superclass).to eq(Attio::Error)
    end

    it "can be raised with a message" do
      expect do
        raise described_class, "Invalid API key"
      end.to raise_error(described_class, "Invalid API key")
    end
  end

  describe Attio::NotFoundError do
    it "is an Attio::Error" do
      expect(described_class.superclass).to eq(Attio::Error)
    end

    it "can be raised with a message" do
      expect { raise described_class, "Record not found" }.to raise_error(described_class, "Record not found")
    end
  end

  describe Attio::ValidationError do
    it "is an Attio::Error" do
      expect(described_class.superclass).to eq(Attio::Error)
    end

    it "can be raised with a message" do
      expect { raise described_class, "Invalid data" }.to raise_error(described_class, "Invalid data")
    end
  end

  describe Attio::RateLimitError do
    it "is an Attio::Error" do
      expect(described_class.superclass).to eq(Attio::Error)
    end

    it "can be raised with a message" do
      expect do
        raise described_class, "Rate limit exceeded"
      end.to raise_error(described_class, "Rate limit exceeded")
    end
  end

  describe Attio::ServerError do
    it "is an Attio::Error" do
      expect(described_class.superclass).to eq(Attio::Error)
    end

    it "can be raised with a message" do
      expect do
        raise described_class, "Internal server error"
      end.to raise_error(described_class, "Internal server error")
    end
  end
end
