# rubocop:todo RSpec/InstanceVariable
require "tmpdir"
require "mittsu/mesh_analysis"

RSpec.describe Mittsu::ProgressiveGLTFExporter do
  let(:mesh) do
    mesh = Mittsu::MeshAnalysis::ProgressiveMesh.new(
      Mittsu::SphereGeometry.new(2.0, 16, 8)
    )
    mesh.progressify
    mesh.name = "mesh"
    mesh
  end
  let(:file) { File.binread(@filename) }
  let(:json) { JSON.parse(file.slice(20, header[0])) }

  around do |example|
    Dir.mktmpdir do |dir|
      @filename = File.join("test.glb")
      Mittsu::GLTFExporter.new.export(mesh, @filename, mode: :binary)
      example.call
    end
  end

  context "when reading chunk 0" do
    let(:header) { file.slice(12, 8).unpack("L<*") }

    it "specifies correct padded chunk length" do
      expect(header[0]).to eq 1168
    end

    it "specifies that this is a JSON chunk" do
      expect(header[1]).to eq 0x4E4F534A # "JSON" as an int
    end

    it "has same buffer length as chunk 1 length" do
      expect(json.dig("buffers", 0, "byteLength")).to eq 3996
    end

    it "specifies extension" do
      expect(json.dig("extensionsUsed", 0)).to eq "MANYFOLD_mesh_progressive"
    end

    context "when checking vertex data bufferView" do
      it "includes bufferView that references the main buffer" do
        expect(json.dig("bufferViews", 2, "buffer")).to eq 0
      end

      it "has correct offset for the bufferView" do
        expect(json.dig("bufferViews", 2, "byteOffset")).to eq 1428
      end

      it "has correct total length for the bufferView" do
        expect(json.dig("bufferViews", 2, "byteLength")).to eq(107 * 24)
      end

      it "has correct stride for the bufferView" do
        expect(json.dig("bufferViews", 2, "byteStride")).to eq 24
      end
    end

    context "when checking displacement data bufferView" do
      it "includes bufferView that references the main buffer" do
        expect(json.dig("bufferViews", 3, "buffer")).to eq 0
      end

      it "is offset by 12 bytes from the vertex data" do
        expect(json.dig("bufferViews", 3, "byteOffset")).to eq json.dig("bufferViews", 2, "byteOffset") + 12
      end

      it "is 12 bytes shorter than the vertex data bufferView" do
        expect(json.dig("bufferViews", 3, "byteLength")).to eq json.dig("bufferViews", 2, "byteLength") - 12
      end

      it "has correct stride for the bufferView" do
        expect(json.dig("bufferViews", 3, "byteStride")).to eq 24
      end
    end

    context "when checking vertex data accessor" do
      it "references correct bufferView" do
        expect(json.dig("accessors", 2, "bufferView")).to eq 2
      end

      it "uses unsigned ints" do
        expect(json.dig("accessors", 2, "componentType")).to eq 5125
      end

      it "specifies number of vertex splits" do
        expect(json.dig("accessors", 2, "count")).to eq 107
      end
    end

    context "when checking displacement data accessor" do
      it "references correct bufferView" do
        expect(json.dig("accessors", 3, "bufferView")).to eq 3
      end

      it "uses floats" do
        expect(json.dig("accessors", 3, "componentType")).to eq 5126
      end

      it "specifies number of vertex splits" do
        expect(json.dig("accessors", 3, "count")).to eq 107
      end
    end

    context "when inspecting mesh structure" do
      it "includes extension data" do
        expect(json.dig("meshes", 0, "extensions", "MANYFOLD_mesh_progressive")).not_to be_nil
      end

      it "references vertex accessor" do
        expect(json.dig("meshes", 0, "extensions", "MANYFOLD_mesh_progressive", "indices")).to eq 2
      end

      it "references displacement accessor" do
        expect(json.dig("meshes", 0, "extensions", "MANYFOLD_mesh_progressive", "attributes", "POSITION")).to eq 3
      end
    end
  end

  context "when reading chunk 1" do
    let(:header) { file.slice(1188, 8).unpack("L<*") }
    let(:vsplit_data) { file.slice(2624..-1) }

    it "specifies correct chunk length" do
      expect(header[0]).to eq 3996
    end

    it "specifies that this is a BIN chunk" do
      expect(header[1]).to eq 0x004E4942 # "BIN" as an int
    end

    it "includes vertex split data" do # rubocop:todo RSpec/ExampleLength
      vsplit = mesh.vertex_splits.first
      expected = [
        vsplit.vertex, vsplit.left, vsplit.right,
        vsplit.displacement.x, vsplit.displacement.y, vsplit.displacement.z
      ]
      vsplit_data.unpack("L<L<L<fff").zip(expected).each do |x|
        expect(x[0]).to be_within(1e-6).of(x[1])
      end
    end
  end
end

# rubocop:enable RSpec/InstanceVariable
