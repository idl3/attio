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
      expect { attributes.get(object: nil, id_or_slug: id_or_slug) }.to raise_error(ArgumentError, "Object type is required")
      expect { attributes.get(object: "", id_or_slug: id_or_slug) }.to raise_error(ArgumentError, "Object type is required")
      expect { attributes.get(object: "  ", id_or_slug: id_or_slug) }.to raise_error(ArgumentError, "Object type is required")
    end

    it "validates id_or_slug parameter" do
      expect { attributes.get(object: object, id_or_slug: nil) }.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect { attributes.get(object: object, id_or_slug: "") }.to raise_error(ArgumentError, "Attribute ID or slug is required")
      expect { attributes.get(object: object, id_or_slug: "  ") }.to raise_error(ArgumentError, "Attribute ID or slug is required")
    end

    it "validates both parameters" do
      expect { attributes.get(object: nil, id_or_slug: nil) }.to raise_error(ArgumentError, "Object type is required")
      expect { attributes.get(object: "", id_or_slug: "") }.to raise_error(ArgumentError, "Object type is required")
    end
  end
end