# frozen_string_literal: true

RSpec.describe Attio::Resources::Objects do
  let(:client) { instance_double(Attio::Client) }
  let(:objects) { described_class.new(client) }

  describe "#list" do
    let(:params) { { limit: 10, offset: 0 } }
    let(:response) { { "data" => [{ "id" => "obj123", "slug" => "contacts" }] } }

    before do
      allow(objects).to receive(:request).and_return(response)
    end

    it "makes a GET request to list objects" do
      expect(objects).to receive(:request).with(:get, "objects", params)
      objects.list(**params)
    end

    it "returns the response" do
      expect(objects.list).to eq(response)
    end

    it "accepts optional parameters" do
      expect(objects).to receive(:request).with(:get, "objects", params)
      objects.list(**params)
    end

    it "works without parameters" do
      expect(objects).to receive(:request).with(:get, "objects", {})
      objects.list
    end
  end

  describe "#get" do
    let(:id_or_slug) { "contacts" }
    let(:response) { { "data" => { "id" => "obj123", "slug" => id_or_slug } } }

    before do
      allow(objects).to receive(:request).and_return(response)
    end

    it "makes a GET request to get an object by id" do
      id = "obj123"
      expect(objects).to receive(:request).with(:get, "objects/#{id}")
      objects.get(id_or_slug: id)
    end

    it "makes a GET request to get an object by slug" do
      expect(objects).to receive(:request).with(:get, "objects/#{id_or_slug}")
      objects.get(id_or_slug: id_or_slug)
    end

    it "returns the response" do
      expect(objects.get(id_or_slug: id_or_slug)).to eq(response)
    end

    it "validates id_or_slug parameter" do
      expect { objects.get(id_or_slug: nil) }.to raise_error(ArgumentError, "Object ID or slug is required")
      expect { objects.get(id_or_slug: "") }.to raise_error(ArgumentError, "Object ID or slug is required")
      expect { objects.get(id_or_slug: "  ") }.to raise_error(ArgumentError, "Object ID or slug is required")
    end
  end
end
