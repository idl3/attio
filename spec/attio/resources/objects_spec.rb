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

  describe "#create" do
    let(:api_slug) { "projects" }
    let(:singular_noun) { "Project" }
    let(:plural_noun) { "Projects" }
    let(:response) do
      {
        "data" => {
          "id" => {
            "workspace_id" => "workspace-123",
            "object_id" => "object-456"
          },
          "api_slug" => api_slug,
          "singular_noun" => singular_noun,
          "plural_noun" => plural_noun,
          "created_at" => "2025-01-12T10:00:00Z"
        }
      }
    end

    context "with valid parameters" do
      it "makes a POST request to create an object" do
        expect(objects).to receive(:request).with(
          :post,
          "objects",
          {
            data: {
              api_slug: api_slug,
              singular_noun: singular_noun,
              plural_noun: plural_noun
            }
          }
        ).and_return(response)

        result = objects.create(
          api_slug: api_slug,
          singular_noun: singular_noun,
          plural_noun: plural_noun
        )

        expect(result).to eq(response)
      end

      it "returns the created object with ID and timestamps" do
        allow(objects).to receive(:request).and_return(response)

        result = objects.create(
          api_slug: api_slug,
          singular_noun: singular_noun,
          plural_noun: plural_noun
        )

        expect(result["data"]["api_slug"]).to eq(api_slug)
        expect(result["data"]["id"]).to include("workspace_id", "object_id")
        expect(result["data"]["created_at"]).to eq("2025-01-12T10:00:00Z")
      end
    end

    context "with invalid parameters" do
      it "validates api_slug is required" do
        expect do
          objects.create(
            api_slug: nil,
            singular_noun: singular_noun,
            plural_noun: plural_noun
          )
        end.to raise_error(ArgumentError, "API slug is required")

        expect do
          objects.create(
            api_slug: "",
            singular_noun: singular_noun,
            plural_noun: plural_noun
          )
        end.to raise_error(ArgumentError, "API slug is required")
      end

      it "validates singular_noun is required" do
        expect do
          objects.create(
            api_slug: api_slug,
            singular_noun: nil,
            plural_noun: plural_noun
          )
        end.to raise_error(ArgumentError, "Singular noun is required")

        expect do
          objects.create(
            api_slug: api_slug,
            singular_noun: "  ",
            plural_noun: plural_noun
          )
        end.to raise_error(ArgumentError, "Singular noun is required")
      end

      it "validates plural_noun is required" do
        expect do
          objects.create(
            api_slug: api_slug,
            singular_noun: singular_noun,
            plural_noun: nil
          )
        end.to raise_error(ArgumentError, "Plural noun is required")

        expect do
          objects.create(
            api_slug: api_slug,
            singular_noun: singular_noun,
            plural_noun: ""
          )
        end.to raise_error(ArgumentError, "Plural noun is required")
      end
    end
  end

  describe "#update" do
    let(:id_or_slug) { "projects" }
    let(:response) do
      {
        "data" => {
          "id" => {
            "workspace_id" => "workspace-123",
            "object_id" => "object-456"
          },
          "api_slug" => "projects",
          "singular_noun" => "Project",
          "plural_noun" => "Active Projects",
          "created_at" => "2025-01-12T10:00:00Z"
        }
      }
    end

    context "with valid parameters" do
      it "makes a PATCH request to update an object with all fields" do
        expect(objects).to receive(:request).with(
          :patch,
          "objects/#{id_or_slug}",
          {
            data: {
              api_slug: "new_projects",
              singular_noun: "New Project",
              plural_noun: "New Projects"
            }
          }
        ).and_return(response)

        result = objects.update(
          id_or_slug: id_or_slug,
          api_slug: "new_projects",
          singular_noun: "New Project",
          plural_noun: "New Projects"
        )

        expect(result).to eq(response)
      end

      it "makes a PATCH request with only api_slug" do
        expect(objects).to receive(:request).with(
          :patch,
          "objects/#{id_or_slug}",
          {
            data: { api_slug: "updated_slug" }
          }
        ).and_return(response)

        objects.update(id_or_slug: id_or_slug, api_slug: "updated_slug")
      end

      it "makes a PATCH request with only singular_noun" do
        expect(objects).to receive(:request).with(
          :patch,
          "objects/#{id_or_slug}",
          {
            data: { singular_noun: "Updated Project" }
          }
        ).and_return(response)

        objects.update(id_or_slug: id_or_slug, singular_noun: "Updated Project")
      end

      it "makes a PATCH request with only plural_noun" do
        expect(objects).to receive(:request).with(
          :patch,
          "objects/#{id_or_slug}",
          {
            data: { plural_noun: "Active Projects" }
          }
        ).and_return(response)

        objects.update(id_or_slug: id_or_slug, plural_noun: "Active Projects")
      end

      it "makes a PATCH request with multiple fields" do
        expect(objects).to receive(:request).with(
          :patch,
          "objects/#{id_or_slug}",
          {
            data: {
              singular_noun: "Task",
              plural_noun: "Tasks"
            }
          }
        ).and_return(response)

        objects.update(
          id_or_slug: id_or_slug,
          singular_noun: "Task",
          plural_noun: "Tasks"
        )
      end
    end

    context "with invalid parameters" do
      it "validates id_or_slug is required" do
        expect do
          objects.update(id_or_slug: nil, api_slug: "new_slug")
        end.to raise_error(ArgumentError, "Object ID or slug is required")

        expect do
          objects.update(id_or_slug: "", plural_noun: "Items")
        end.to raise_error(ArgumentError, "Object ID or slug is required")

        expect do
          objects.update(id_or_slug: "  ", singular_noun: "Item")
        end.to raise_error(ArgumentError, "Object ID or slug is required")
      end

      it "requires at least one field to update" do
        expect do
          objects.update(id_or_slug: id_or_slug)
        end.to raise_error(ArgumentError, "At least one field to update is required")
      end

      it "ignores nil optional parameters" do
        expect(objects).to receive(:request).with(
          :patch,
          "objects/#{id_or_slug}",
          {
            data: { api_slug: "new_slug" }
          }
        ).and_return(response)

        objects.update(
          id_or_slug: id_or_slug,
          api_slug: "new_slug",
          singular_noun: nil,
          plural_noun: nil
        )
      end
    end
  end
end
