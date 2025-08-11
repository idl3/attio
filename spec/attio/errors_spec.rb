RSpec.describe "Attio Errors" do
  describe Attio::Error do
    it "is a StandardError" do
      expect(Attio::Error.superclass).to eq(StandardError)
    end
  end

  describe Attio::AuthenticationError do
    it "is an Attio::Error" do
      expect(Attio::AuthenticationError.superclass).to eq(Attio::Error)
    end

    it "can be raised with a message" do
      expect { raise Attio::AuthenticationError, "Invalid API key" }.to raise_error(Attio::AuthenticationError, "Invalid API key")
    end
  end

  describe Attio::NotFoundError do
    it "is an Attio::Error" do
      expect(Attio::NotFoundError.superclass).to eq(Attio::Error)
    end

    it "can be raised with a message" do
      expect { raise Attio::NotFoundError, "Record not found" }.to raise_error(Attio::NotFoundError, "Record not found")
    end
  end

  describe Attio::ValidationError do
    it "is an Attio::Error" do
      expect(Attio::ValidationError.superclass).to eq(Attio::Error)
    end

    it "can be raised with a message" do
      expect { raise Attio::ValidationError, "Invalid data" }.to raise_error(Attio::ValidationError, "Invalid data")
    end
  end

  describe Attio::RateLimitError do
    it "is an Attio::Error" do
      expect(Attio::RateLimitError.superclass).to eq(Attio::Error)
    end

    it "can be raised with a message" do
      expect { raise Attio::RateLimitError, "Rate limit exceeded" }.to raise_error(Attio::RateLimitError, "Rate limit exceeded")
    end
  end

  describe Attio::ServerError do
    it "is an Attio::Error" do
      expect(Attio::ServerError.superclass).to eq(Attio::Error)
    end

    it "can be raised with a message" do
      expect { raise Attio::ServerError, "Internal server error" }.to raise_error(Attio::ServerError, "Internal server error")
    end
  end
end