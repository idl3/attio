# frozen_string_literal: true

RSpec.describe Attio::Resources::Attributes do
  let(:client) { instance_double(Attio::Client) }
  let(:attributes) { described_class.new(client) }

  describe "#list" do
    let(:object) { "contacts" }
    let(:params) { { limit: 10, offset: 0 } }
    let(:response) { { "data" => [{ "id" => "attr123", "slug" => "email", "name" => "Email" }] } }

    before do
      allow(attributes).to receive(:request).and_return(response)
    end

    it "makes a GET request to list attributes" do
      expect(attributes).to receive(:request).with(:get, "objects/#{object}/attributes", params)
      attributes.list(object: object, **params)
    end

    it "returns the response" do
      expect(attributes.list(object: object)).to eq(response)
    end

    it "validates object parameter" do
      expect { attributes.list(object: nil) }.to raise_error(ArgumentError, "Object type is required")
      expect { attributes.list(object: "") }.to raise_error(ArgumentError, "Object type is required")
      expect { attributes.list(object: "  ") }.to raise_error(ArgumentError, "Object type is required")
    end

    it "accepts optional parameters" do
      expect(attributes).to receive(:request).with(:get, "objects/#{object}/attributes", params)
      attributes.list(object: object, **params)
    end

    it "works with only required parameters" do
      expect(attributes).to receive(:request).with(:get, "objects/#{object}/attributes", {})
      attributes.list(object: object)
    end
  end

  describe "#get" do
    let(:object) { "contacts" }
    let(:id_or_slug) { "email" }
    let(:response) { { "data" => { "id" => "attr123", "slug" => id_or_slug, "name" => "Email" } } }

    before do
      allow(attributes).to receive(:request).and_return(response)
    end

    it "makes a GET request to get an attribute by id" do
      id = "attr123"
      expect(attributes).to receive(:request).with(:get, "objects/#{object}/attributes/#{id}")
      attributes.get(object: object, id_or_slug: id)
    end

    it "makes a GET request to get an attribute by slug" do
      expect(attributes).to receive(:request).with(:get, "objects/#{object}/attributes/#{id_or_slug}")
      attributes.get(object: object, id_or_slug: id_or_slug)
    end

    it "returns the response" do
      expect(attributes.get(object: object, id_or_slug: id_or_slug)).to eq(response)
    end

    it "validates object parameter" do
      expect do
        attributes.get(object: nil, id_or_slug: id_or_slug)
      end.to raise_error(ArgumentError, "Object type is required")
      expect do
        attributes.get(object: "", id_or_slug: id_or_slug)
      end.to raise_error(ArgumentError, "Object type is required")
      expect do
        attributes.get(object: "  ", id_or_slug: id_or_slug)
      end.to raise_error(ArgumentError, "Object type is required")
    end

    it "validates id_or_slug parameter" do
      expect do
        attributes.get(object: object, id_or_slug: nil)
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect do
        attributes.get(object: object, id_or_slug: "")
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect do
        attributes.get(object: object, id_or_slug: "  ")
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
    end

    it "validates both parameters" do
      expect { attributes.get(object: nil, id_or_slug: nil) }.to raise_error(ArgumentError, "Object type is required")
      expect { attributes.get(object: "", id_or_slug: "") }.to raise_error(ArgumentError, "Object type is required")
    end
  end

  describe "#create" do
    let(:object) { "contacts" }
    let(:data) { { title: "Status", api_slug: "status", type: "select" } }
    let(:response) { { "data" => { "id" => "attr123", "slug" => "status", "title" => "Status" } } }

    before do
      allow(attributes).to receive(:request).and_return(response)
    end

    it "makes a POST request to create an attribute" do
      expected_payload = { data: data }
      expect(attributes).to receive(:request).with(:post, "objects/#{object}/attributes", expected_payload)
      attributes.create(object: object, data: data)
    end

    it "returns the response" do
      expect(attributes.create(object: object, data: data)).to eq(response)
    end

    it "validates object parameter" do
      expect { attributes.create(object: nil, data: data) }.to raise_error(ArgumentError, "Object type is required")
      expect { attributes.create(object: "", data: data) }.to raise_error(ArgumentError, "Object type is required")
      expect { attributes.create(object: "  ", data: data) }.to raise_error(ArgumentError, "Object type is required")
    end

    it "validates data parameter" do
      expect { attributes.create(object: object, data: nil) }.to raise_error(ArgumentError, "Attribute data must be a hash")
      expect { attributes.create(object: object, data: "not a hash") }.to raise_error(ArgumentError, "Attribute data must be a hash")
      expect { attributes.create(object: object, data: []) }.to raise_error(ArgumentError, "Attribute data must be a hash")
    end
  end

  describe "#update" do
    let(:object) { "contacts" }
    let(:id_or_slug) { "status" }
    let(:data) { { title: "Contact Status", description: "The current status of the contact" } }
    let(:response) { { "data" => { "id" => "attr123", "slug" => id_or_slug, "title" => "Contact Status" } } }

    before do
      allow(attributes).to receive(:request).and_return(response)
    end

    it "makes a PATCH request to update an attribute by id" do
      id = "attr123"
      expected_payload = { data: data }
      expect(attributes).to receive(:request).with(:patch, "objects/#{object}/attributes/#{id}", expected_payload)
      attributes.update(object: object, id_or_slug: id, data: data)
    end

    it "makes a PATCH request to update an attribute by slug" do
      expected_payload = { data: data }
      expect(attributes).to receive(:request).with(:patch, "objects/#{object}/attributes/#{id_or_slug}", expected_payload)
      attributes.update(object: object, id_or_slug: id_or_slug, data: data)
    end

    it "returns the response" do
      expect(attributes.update(object: object, id_or_slug: id_or_slug, data: data)).to eq(response)
    end

    it "validates object parameter" do
      expect do
        attributes.update(object: nil, id_or_slug: id_or_slug, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
      expect do
        attributes.update(object: "", id_or_slug: id_or_slug, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
      expect do
        attributes.update(object: "  ", id_or_slug: id_or_slug, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
    end

    it "validates id_or_slug parameter" do
      expect do
        attributes.update(object: object, id_or_slug: nil, data: data)
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect do
        attributes.update(object: object, id_or_slug: "", data: data)
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect do
        attributes.update(object: object, id_or_slug: "  ", data: data)
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
    end

    it "validates data parameter" do
      expect do
        attributes.update(object: object, id_or_slug: id_or_slug, data: nil)
      end.to raise_error(ArgumentError, "Attribute data must be a hash")
      expect do
        attributes.update(object: object, id_or_slug: id_or_slug, data: "not a hash")
      end.to raise_error(ArgumentError, "Attribute data must be a hash")
      expect do
        attributes.update(object: object, id_or_slug: id_or_slug, data: [])
      end.to raise_error(ArgumentError, "Attribute data must be a hash")
    end

    it "validates both parameters" do
      expect { attributes.update(object: nil, id_or_slug: nil, data: data) }.to raise_error(ArgumentError, "Object type is required")
      expect { attributes.update(object: "", id_or_slug: "", data: data) }.to raise_error(ArgumentError, "Object type is required")
    end
  end

  describe "#list_options" do
    let(:object) { "deals" }
    let(:id_or_slug) { "deal_stage" }
    let(:params) { { limit: 10, offset: 0 } }
    let(:response) { { "data" => [{ "id" => "opt123", "title" => "Lead", "value" => "lead" }] } }

    before do
      allow(attributes).to receive(:request).and_return(response)
    end

    it "makes a GET request to list attribute options" do
      expect(attributes).to receive(:request).with(:get, "objects/#{object}/attributes/#{id_or_slug}/options", params)
      attributes.list_options(object: object, id_or_slug: id_or_slug, **params)
    end

    it "returns the response" do
      expect(attributes.list_options(object: object, id_or_slug: id_or_slug)).to eq(response)
    end

    it "validates object parameter" do
      expect { attributes.list_options(object: nil, id_or_slug: id_or_slug) }.to raise_error(ArgumentError, "Object type is required")
      expect { attributes.list_options(object: "", id_or_slug: id_or_slug) }.to raise_error(ArgumentError, "Object type is required")
      expect { attributes.list_options(object: "  ", id_or_slug: id_or_slug) }.to raise_error(ArgumentError, "Object type is required")
    end

    it "validates id_or_slug parameter" do
      expect { attributes.list_options(object: object, id_or_slug: nil) }.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect { attributes.list_options(object: object, id_or_slug: "") }.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect { attributes.list_options(object: object, id_or_slug: "  ") }.to raise_error(ArgumentError, "Attribute ID or slug is required")
    end

    it "accepts optional parameters" do
      expect(attributes).to receive(:request).with(:get, "objects/#{object}/attributes/#{id_or_slug}/options", params)
      attributes.list_options(object: object, id_or_slug: id_or_slug, **params)
    end

    it "works with only required parameters" do
      expect(attributes).to receive(:request).with(:get, "objects/#{object}/attributes/#{id_or_slug}/options", {})
      attributes.list_options(object: object, id_or_slug: id_or_slug)
    end
  end

  describe "#create_option" do
    let(:object) { "deals" }
    let(:id_or_slug) { "deal_stage" }
    let(:data) { { title: "Negotiation", value: "negotiation", color: "blue" } }
    let(:response) { { "data" => { "id" => "opt123", "title" => "Negotiation", "value" => "negotiation" } } }

    before do
      allow(attributes).to receive(:request).and_return(response)
    end

    it "makes a POST request to create an attribute option" do
      expect(attributes).to receive(:request).with(:post, "objects/#{object}/attributes/#{id_or_slug}/options", data)
      attributes.create_option(object: object, id_or_slug: id_or_slug, data: data)
    end

    it "returns the response" do
      expect(attributes.create_option(object: object, id_or_slug: id_or_slug, data: data)).to eq(response)
    end

    it "validates object parameter" do
      expect do
        attributes.create_option(object: nil, id_or_slug: id_or_slug, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
      expect do
        attributes.create_option(object: "", id_or_slug: id_or_slug, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
      expect do
        attributes.create_option(object: "  ", id_or_slug: id_or_slug, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
    end

    it "validates id_or_slug parameter" do
      expect do
        attributes.create_option(object: object, id_or_slug: nil, data: data)
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect do
        attributes.create_option(object: object, id_or_slug: "", data: data)
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect do
        attributes.create_option(object: object, id_or_slug: "  ", data: data)
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
    end

    it "validates data parameter" do
      expect do
        attributes.create_option(object: object, id_or_slug: id_or_slug, data: nil)
      end.to raise_error(ArgumentError, "Option data must be a hash")
      expect do
        attributes.create_option(object: object, id_or_slug: id_or_slug, data: "not a hash")
      end.to raise_error(ArgumentError, "Option data must be a hash")
      expect do
        attributes.create_option(object: object, id_or_slug: id_or_slug, data: [])
      end.to raise_error(ArgumentError, "Option data must be a hash")
    end
  end

  describe "#update_option" do
    let(:object) { "deals" }
    let(:id_or_slug) { "deal_stage" }
    let(:option) { "negotiation" }
    let(:data) { { title: "In Negotiation", color: "orange" } }
    let(:response) { { "data" => { "id" => "opt123", "title" => "In Negotiation", "value" => "negotiation" } } }

    before do
      allow(attributes).to receive(:request).and_return(response)
    end

    it "makes a PATCH request to update an attribute option" do
      expect(attributes).to receive(:request).with(:patch, "objects/#{object}/attributes/#{id_or_slug}/options/#{option}", data)
      attributes.update_option(object: object, id_or_slug: id_or_slug, option: option, data: data)
    end

    it "returns the response" do
      expect(attributes.update_option(object: object, id_or_slug: id_or_slug, option: option, data: data)).to eq(response)
    end

    it "validates object parameter" do
      expect do
        attributes.update_option(object: nil, id_or_slug: id_or_slug, option: option, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
      expect do
        attributes.update_option(object: "", id_or_slug: id_or_slug, option: option, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
      expect do
        attributes.update_option(object: "  ", id_or_slug: id_or_slug, option: option, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
    end

    it "validates id_or_slug parameter" do
      expect do
        attributes.update_option(object: object, id_or_slug: nil, option: option, data: data)
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect do
        attributes.update_option(object: object, id_or_slug: "", option: option, data: data)
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect do
        attributes.update_option(object: object, id_or_slug: "  ", option: option, data: data)
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
    end

    it "validates option parameter" do
      expect do
        attributes.update_option(object: object, id_or_slug: id_or_slug, option: nil, data: data)
      end.to raise_error(ArgumentError, "Option ID is required")
      expect do
        attributes.update_option(object: object, id_or_slug: id_or_slug, option: "", data: data)
      end.to raise_error(ArgumentError, "Option ID is required")
      expect do
        attributes.update_option(object: object, id_or_slug: id_or_slug, option: "  ", data: data)
      end.to raise_error(ArgumentError, "Option ID is required")
    end

    it "validates data parameter" do
      expect do
        attributes.update_option(object: object, id_or_slug: id_or_slug, option: option, data: nil)
      end.to raise_error(ArgumentError, "Option data must be a hash")
      expect do
        attributes.update_option(object: object, id_or_slug: id_or_slug, option: option, data: "not a hash")
      end.to raise_error(ArgumentError, "Option data must be a hash")
      expect do
        attributes.update_option(object: object, id_or_slug: id_or_slug, option: option, data: [])
      end.to raise_error(ArgumentError, "Option data must be a hash")
    end
  end

  describe "#list_statuses" do
    let(:object) { "deals" }
    let(:id_or_slug) { "deal_status" }
    let(:params) { { limit: 10, offset: 0 } }
    let(:response) { { "data" => [{ "id" => "stat123", "title" => "Open", "value" => "open" }] } }

    before do
      allow(attributes).to receive(:request).and_return(response)
    end

    it "makes a GET request to list attribute statuses" do
      expect(attributes).to receive(:request).with(:get, "objects/#{object}/attributes/#{id_or_slug}/statuses", params)
      attributes.list_statuses(object: object, id_or_slug: id_or_slug, **params)
    end

    it "returns the response" do
      expect(attributes.list_statuses(object: object, id_or_slug: id_or_slug)).to eq(response)
    end

    it "validates object parameter" do
      expect { attributes.list_statuses(object: nil, id_or_slug: id_or_slug) }.to raise_error(ArgumentError, "Object type is required")
      expect { attributes.list_statuses(object: "", id_or_slug: id_or_slug) }.to raise_error(ArgumentError, "Object type is required")
      expect { attributes.list_statuses(object: "  ", id_or_slug: id_or_slug) }.to raise_error(ArgumentError, "Object type is required")
    end

    it "validates id_or_slug parameter" do
      expect { attributes.list_statuses(object: object, id_or_slug: nil) }.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect { attributes.list_statuses(object: object, id_or_slug: "") }.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect { attributes.list_statuses(object: object, id_or_slug: "  ") }.to raise_error(ArgumentError, "Attribute ID or slug is required")
    end

    it "accepts optional parameters" do
      expect(attributes).to receive(:request).with(:get, "objects/#{object}/attributes/#{id_or_slug}/statuses", params)
      attributes.list_statuses(object: object, id_or_slug: id_or_slug, **params)
    end

    it "works with only required parameters" do
      expect(attributes).to receive(:request).with(:get, "objects/#{object}/attributes/#{id_or_slug}/statuses", {})
      attributes.list_statuses(object: object, id_or_slug: id_or_slug)
    end
  end

  describe "#create_status" do
    let(:object) { "deals" }
    let(:id_or_slug) { "deal_status" }
    let(:data) { { title: "Under Review", value: "under_review", color: "yellow" } }
    let(:response) { { "data" => { "id" => "stat123", "title" => "Under Review", "value" => "under_review" } } }

    before do
      allow(attributes).to receive(:request).and_return(response)
    end

    it "makes a POST request to create an attribute status" do
      expect(attributes).to receive(:request).with(:post, "objects/#{object}/attributes/#{id_or_slug}/statuses", data)
      attributes.create_status(object: object, id_or_slug: id_or_slug, data: data)
    end

    it "returns the response" do
      expect(attributes.create_status(object: object, id_or_slug: id_or_slug, data: data)).to eq(response)
    end

    it "validates object parameter" do
      expect do
        attributes.create_status(object: nil, id_or_slug: id_or_slug, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
      expect do
        attributes.create_status(object: "", id_or_slug: id_or_slug, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
      expect do
        attributes.create_status(object: "  ", id_or_slug: id_or_slug, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
    end

    it "validates id_or_slug parameter" do
      expect do
        attributes.create_status(object: object, id_or_slug: nil, data: data)
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect do
        attributes.create_status(object: object, id_or_slug: "", data: data)
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect do
        attributes.create_status(object: object, id_or_slug: "  ", data: data)
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
    end

    it "validates data parameter" do
      expect do
        attributes.create_status(object: object, id_or_slug: id_or_slug, data: nil)
      end.to raise_error(ArgumentError, "Status data must be a hash")
      expect do
        attributes.create_status(object: object, id_or_slug: id_or_slug, data: "not a hash")
      end.to raise_error(ArgumentError, "Status data must be a hash")
      expect do
        attributes.create_status(object: object, id_or_slug: id_or_slug, data: [])
      end.to raise_error(ArgumentError, "Status data must be a hash")
    end
  end

  describe "#update_status" do
    let(:object) { "deals" }
    let(:id_or_slug) { "deal_status" }
    let(:status) { "under_review" }
    let(:data) { { title: "Pending Review", color: "orange" } }
    let(:response) { { "data" => { "id" => "stat123", "title" => "Pending Review", "value" => "under_review" } } }

    before do
      allow(attributes).to receive(:request).and_return(response)
    end

    it "makes a PATCH request to update an attribute status" do
      expect(attributes).to receive(:request).with(:patch, "objects/#{object}/attributes/#{id_or_slug}/statuses/#{status}", data)
      attributes.update_status(object: object, id_or_slug: id_or_slug, status: status, data: data)
    end

    it "returns the response" do
      expect(attributes.update_status(object: object, id_or_slug: id_or_slug, status: status, data: data)).to eq(response)
    end

    it "validates object parameter" do
      expect do
        attributes.update_status(object: nil, id_or_slug: id_or_slug, status: status, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
      expect do
        attributes.update_status(object: "", id_or_slug: id_or_slug, status: status, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
      expect do
        attributes.update_status(object: "  ", id_or_slug: id_or_slug, status: status, data: data)
      end.to raise_error(ArgumentError, "Object type is required")
    end

    it "validates id_or_slug parameter" do
      expect do
        attributes.update_status(object: object, id_or_slug: nil, status: status, data: data)
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect do
        attributes.update_status(object: object, id_or_slug: "", status: status, data: data)
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect do
        attributes.update_status(object: object, id_or_slug: "  ", status: status, data: data)
      end.to raise_error(ArgumentError, "Attribute ID or slug is required")
    end

    it "validates status parameter" do
      expect do
        attributes.update_status(object: object, id_or_slug: id_or_slug, status: nil, data: data)
      end.to raise_error(ArgumentError, "Status ID is required")
      expect do
        attributes.update_status(object: object, id_or_slug: id_or_slug, status: "", data: data)
      end.to raise_error(ArgumentError, "Status ID is required")
      expect do
        attributes.update_status(object: object, id_or_slug: id_or_slug, status: "  ", data: data)
      end.to raise_error(ArgumentError, "Status ID is required")
    end

    it "validates data parameter" do
      expect do
        attributes.update_status(object: object, id_or_slug: id_or_slug, status: status, data: nil)
      end.to raise_error(ArgumentError, "Status data must be a hash")
      expect do
        attributes.update_status(object: object, id_or_slug: id_or_slug, status: status, data: "not a hash")
      end.to raise_error(ArgumentError, "Status data must be a hash")
      expect do
        attributes.update_status(object: object, id_or_slug: id_or_slug, status: status, data: [])
      end.to raise_error(ArgumentError, "Status data must be a hash")
    end
  end
end
