RSpec.describe Attio::Resources::Base do
  let(:client) { instance_double(Attio::Client) }
  let(:connection) { instance_double(Attio::HttpClient) }
  let(:resource) { described_class.new(client) }

  before do
    allow(client).to receive(:connection).and_return(connection)
  end

  describe "#initialize" do
    it "requires a client" do
      expect { described_class.new(nil) }.to raise_error(ArgumentError, "Client is required")
    end

    it "sets the client" do
      expect(resource.client).to eq(client)
    end
  end

  describe "#request" do
    let(:path) { "test/path" }
    let(:params) { { key: "value" } }
    let(:response) { { "data" => "test" } }

    context "with GET request" do
      it "makes a GET request" do
        expect(connection).to receive(:get).with(path, params).and_return(response)
        result = resource.send(:request, :get, path, params)
        expect(result).to eq({ "data" => "test" })
      end
    end

    context "with POST request" do
      it "makes a POST request" do
        expect(connection).to receive(:post).with(path, params).and_return(response)
        result = resource.send(:request, :post, path, params)
        expect(result).to eq({ "data" => "test" })
      end
    end

    context "with PATCH request" do
      it "makes a PATCH request" do
        expect(connection).to receive(:patch).with(path, params).and_return(response)
        result = resource.send(:request, :patch, path, params)
        expect(result).to eq({ "data" => "test" })
      end
    end

    context "with PUT request" do
      it "makes a PUT request" do
        expect(connection).to receive(:put).with(path, params).and_return(response)
        result = resource.send(:request, :put, path, params)
        expect(result).to eq({ "data" => "test" })
      end
    end

    context "with DELETE request" do
      it "makes a DELETE request" do
        expect(connection).to receive(:delete).with(path).and_return(response)
        result = resource.send(:request, :delete, path)
        expect(result).to eq({ "data" => "test" })
      end
    end

    context "with unsupported method" do
      it "raises ArgumentError" do
        expect { resource.send(:request, :invalid, path) }.to raise_error(ArgumentError, "Unsupported HTTP method: invalid")
      end
    end
  end
end