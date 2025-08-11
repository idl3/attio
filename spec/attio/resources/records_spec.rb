# frozen_string_literal: true

RSpec.describe Attio::Resources::Records do
  let(:client) { instance_double(Attio::Client) }
  let(:records) { described_class.new(client) }

  describe "#list" do
    let(:object) { "contacts" }
    let(:params) { { limit: 10, offset: 0 } }
    let(:response) { { "data" => [{ "id" => "123" }] } }

    before do
      allow(records).to receive(:request).and_return(response)
    end

    it "makes a POST request to list records" do
      expect(records).to receive(:request).with(:post, "objects/#{object}/records/query", params)
      records.list(object: object, **params)
    end

    it "returns the response" do
      expect(records.list(object: object)).to eq(response)
    end

    it "validates object parameter" do
      expect { records.list(object: nil) }.to raise_error(ArgumentError, "Object type is required")
      expect { records.list(object: "") }.to raise_error(ArgumentError, "Object type is required")
      expect { records.list(object: "  ") }.to raise_error(ArgumentError, "Object type is required")
    end
  end

  describe "#get" do
    let(:object) { "contacts" }
    let(:id) { "record123" }
    let(:response) { { "data" => { "id" => id } } }

    before do
      allow(records).to receive(:request).and_return(response)
    end

    it "makes a GET request to get a record" do
      expect(records).to receive(:request).with(:get, "objects/#{object}/records/#{id}")
      records.get(object: object, id: id)
    end

    it "returns the response" do
      expect(records.get(object: object, id: id)).to eq(response)
    end

    it "validates object parameter" do
      expect { records.get(object: nil, id: id) }.to raise_error(ArgumentError, "Object type is required")
      expect { records.get(object: "", id: id) }.to raise_error(ArgumentError, "Object type is required")
    end

    it "validates id parameter" do
      expect { records.get(object: object, id: nil) }.to raise_error(ArgumentError, "Record ID is required")
      expect { records.get(object: object, id: "") }.to raise_error(ArgumentError, "Record ID is required")
      expect { records.get(object: object, id: "  ") }.to raise_error(ArgumentError, "Record ID is required")
    end
  end

  describe "#create" do
    let(:object) { "contacts" }
    let(:data) { { values: { name: "John Doe", email: "john@example.com" } } }
    let(:response) { { "data" => { "id" => "new123" } } }

    before do
      allow(records).to receive(:request).and_return(response)
    end

    it "makes a POST request to create a record" do
      expect(records).to receive(:request).with(:post, "objects/#{object}/records", data)
      records.create(object: object, data: data)
    end

    it "returns the response" do
      expect(records.create(object: object, data: data)).to eq(response)
    end

    it "validates object parameter" do
      expect { records.create(object: nil, data: data) }.to raise_error(ArgumentError, "Object type is required")
      expect { records.create(object: "", data: data) }.to raise_error(ArgumentError, "Object type is required")
    end

    it "validates data parameter" do
      expect { records.create(object: object, data: nil) }.to raise_error(ArgumentError, "Data is required")
      expect { records.create(object: object, data: "not a hash") }.to raise_error(ArgumentError, "Data must be a hash")
      expect { records.create(object: object, data: []) }.to raise_error(ArgumentError, "Data must be a hash")
    end
  end

  describe "#update" do
    let(:object) { "contacts" }
    let(:id) { "record123" }
    let(:data) { { values: { name: "Jane Doe" } } }
    let(:response) { { "data" => { "id" => id } } }

    before do
      allow(records).to receive(:request).and_return(response)
    end

    it "makes a PATCH request to update a record" do
      expect(records).to receive(:request).with(:patch, "objects/#{object}/records/#{id}", data)
      records.update(object: object, id: id, data: data)
    end

    it "returns the response" do
      expect(records.update(object: object, id: id, data: data)).to eq(response)
    end

    it "validates object parameter" do
      expect do
        records.update(object: nil, id: id, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
      expect { records.update(object: "", id: id, data: data) }.to raise_error(ArgumentError, "Object type is required")
    end

    it "validates id parameter" do
      expect do
        records.update(object: object, id: nil, data: data)
      end.to raise_error(ArgumentError, "Record ID is required")
      expect do
        records.update(object: object, id: "", data: data)
      end.to raise_error(ArgumentError, "Record ID is required")
    end

    it "validates data parameter" do
      expect { records.update(object: object, id: id, data: nil) }.to raise_error(ArgumentError, "Data is required")
      expect do
        records.update(object: object, id: id, data: "not a hash")
      end.to raise_error(ArgumentError, "Data must be a hash")
    end
  end

  describe "#delete" do
    let(:object) { "contacts" }
    let(:id) { "record123" }
    let(:response) { { "success" => true } }

    before do
      allow(records).to receive(:request).and_return(response)
    end

    it "makes a DELETE request to delete a record" do
      expect(records).to receive(:request).with(:delete, "objects/#{object}/records/#{id}")
      records.delete(object: object, id: id)
    end

    it "returns the response" do
      expect(records.delete(object: object, id: id)).to eq(response)
    end

    it "validates object parameter" do
      expect { records.delete(object: nil, id: id) }.to raise_error(ArgumentError, "Object type is required")
      expect { records.delete(object: "", id: id) }.to raise_error(ArgumentError, "Object type is required")
    end

    it "validates id parameter" do
      expect { records.delete(object: object, id: nil) }.to raise_error(ArgumentError, "Record ID is required")
      expect { records.delete(object: object, id: "") }.to raise_error(ArgumentError, "Record ID is required")
    end
  end
end
