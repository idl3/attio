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

    it "makes a POST request to query records" do
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

  describe "#assert" do
    let(:object) { "contacts" }
    let(:matching_attribute) { "email" }
    let(:data) { { values: { name: "John Doe", email: "john@example.com" } } }
    let(:request_body) { { data: data, matching_attribute: matching_attribute } }
    let(:response) { { "data" => { "id" => "upserted123" } } }

    before do
      allow(records).to receive(:request).and_return(response)
    end

    it "makes a PUT request to assert a record" do
      expect(records).to receive(:request).with(:put, "objects/#{object}/records", request_body)
      records.assert(object: object, matching_attribute: matching_attribute, data: data)
    end

    it "returns the response" do
      expect(records.assert(object: object, matching_attribute: matching_attribute, data: data)).to eq(response)
    end

    it "validates object parameter" do
      expect do
        records.assert(object: nil, matching_attribute: matching_attribute, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
      expect do
        records.assert(object: "", matching_attribute: matching_attribute, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
      expect do
        records.assert(object: "  ", matching_attribute: matching_attribute, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
    end

    it "validates matching_attribute parameter" do
      expect do
        records.assert(object: object, matching_attribute: nil, data: data)
      end.to raise_error(ArgumentError, "Matching attribute is required")
      expect do
        records.assert(object: object, matching_attribute: "", data: data)
      end.to raise_error(ArgumentError, "Matching attribute is required")
      expect do
        records.assert(object: object, matching_attribute: "  ", data: data)
      end.to raise_error(ArgumentError, "Matching attribute is required")
    end

    it "validates data parameter" do
      expect do
        records.assert(object: object, matching_attribute: matching_attribute, data: nil)
      end.to raise_error(ArgumentError, "Data is required")
      expect do
        records.assert(object: object, matching_attribute: matching_attribute, data: "not a hash")
      end.to raise_error(ArgumentError, "Data must be a hash")
      expect do
        records.assert(object: object, matching_attribute: matching_attribute, data: [])
      end.to raise_error(ArgumentError, "Data must be a hash")
    end

    it "includes matching_attribute in request body" do
      expect(records).to receive(:request).with(
        :put, 
        "objects/#{object}/records", 
        hash_including(matching_attribute: matching_attribute)
      )
      records.assert(object: object, matching_attribute: matching_attribute, data: data)
    end

    it "wraps data in data key in request body" do
      expect(records).to receive(:request).with(
        :put, 
        "objects/#{object}/records", 
        hash_including(data: data)
      )
      records.assert(object: object, matching_attribute: matching_attribute, data: data)
    end

    context "with different matching attributes" do
      ["email", "name", "phone", "external_id"].each do |attr|
        it "works with #{attr} as matching attribute" do
          expect(records).to receive(:request).with(
            :put, 
            "objects/#{object}/records", 
            hash_including(matching_attribute: attr)
          )
          records.assert(object: object, matching_attribute: attr, data: data)
        end
      end
    end

    context "with complex data structures" do
      let(:complex_data) do
        {
          values: {
            name: "John Doe",
            email: "john@example.com",
            company: { target_object: "companies", target_record_id: "company123" },
            tags: ["customer", "lead"],
            notes: { content: "Important customer" }
          }
        }
      end

      it "handles complex data structures" do
        expect(records).to receive(:request).with(
          :put, 
          "objects/#{object}/records", 
          hash_including(data: complex_data)
        )
        records.assert(object: object, matching_attribute: matching_attribute, data: complex_data)
      end
    end
  end

  describe "#update_with_put" do
    let(:object) { "contacts" }
    let(:id) { "record123" }
    let(:data) { { values: { name: "Jane Doe", tags: ["vip", "customer"] } } }
    let(:request_body) { { data: data } }
    let(:response) { { "data" => { "id" => id } } }

    before do
      allow(records).to receive(:request).and_return(response)
    end

    it "makes a PUT request to replace a record" do
      expect(records).to receive(:request).with(:put, "objects/#{object}/records/#{id}", request_body)
      records.update_with_put(object: object, id: id, data: data)
    end

    it "returns the response" do
      expect(records.update_with_put(object: object, id: id, data: data)).to eq(response)
    end

    it "validates object parameter" do
      expect do
        records.update_with_put(object: nil, id: id, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
      expect do
        records.update_with_put(object: "", id: id, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
      expect do
        records.update_with_put(object: "  ", id: id, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
    end

    it "validates id parameter" do
      expect do
        records.update_with_put(object: object, id: nil, data: data)
      end.to raise_error(ArgumentError, "Record ID is required")
      expect do
        records.update_with_put(object: object, id: "", data: data)
      end.to raise_error(ArgumentError, "Record ID is required")
      expect do
        records.update_with_put(object: object, id: "  ", data: data)
      end.to raise_error(ArgumentError, "Record ID is required")
    end

    it "validates data parameter" do
      expect do
        records.update_with_put(object: object, id: id, data: nil)
      end.to raise_error(ArgumentError, "Data is required")
      expect do
        records.update_with_put(object: object, id: id, data: "not a hash")
      end.to raise_error(ArgumentError, "Data must be a hash")
      expect do
        records.update_with_put(object: object, id: id, data: [])
      end.to raise_error(ArgumentError, "Data must be a hash")
    end

    it "wraps data in data key in request body" do
      expect(records).to receive(:request).with(
        :put, 
        "objects/#{object}/records/#{id}", 
        hash_including(data: data)
      )
      records.update_with_put(object: object, id: id, data: data)
    end

    context "with multiselect field replacement" do
      let(:multiselect_data) do
        {
          values: {
            name: "John Doe",
            tags: ["new_tag1", "new_tag2"],  # This should replace all existing tags
            categories: ["cat1", "cat2"]     # This should replace all existing categories
          }
        }
      end

      it "handles multiselect field replacement" do
        expect(records).to receive(:request).with(
          :put, 
          "objects/#{object}/records/#{id}", 
          hash_including(data: multiselect_data)
        )
        records.update_with_put(object: object, id: id, data: multiselect_data)
      end
    end

    context "with complex data structures" do
      let(:complex_data) do
        {
          values: {
            name: "Jane Smith",
            email: "jane.smith@example.com",
            company: { target_object: "companies", target_record_id: "company456" },
            addresses: [
              {
                type: "work",
                line_1: "123 Business Ave",
                city: "San Francisco",
                state: "CA"
              }
            ],
            custom_fields: {
              priority: "high",
              source: "referral"
            }
          }
        }
      end

      it "handles complex data structures" do
        expect(records).to receive(:request).with(
          :put, 
          "objects/#{object}/records/#{id}", 
          hash_including(data: complex_data)
        )
        records.update_with_put(object: object, id: id, data: complex_data)
      end
    end

    context "comparison with regular update method" do
      it "uses PUT method instead of PATCH" do
        expect(records).to receive(:request).with(:put, anything, anything)
        records.update_with_put(object: object, id: id, data: data)
      end

      it "differs from update method which uses PATCH" do
        allow(records).to receive(:request)
        
        records.update(object: object, id: id, data: data)
        expect(records).to have_received(:request).with(:patch, "objects/#{object}/records/#{id}", data)
        
        records.update_with_put(object: object, id: id, data: data)
        expect(records).to have_received(:request).with(:put, "objects/#{object}/records/#{id}", request_body)
      end
    end

    context "with empty data" do
      let(:empty_data) { {} }

      it "handles empty data hash" do
        expect(records).to receive(:request).with(
          :put, 
          "objects/#{object}/records/#{id}", 
          { data: empty_data }
        )
        records.update_with_put(object: object, id: id, data: empty_data)
      end
    end
  end
end
