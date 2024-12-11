# rubocop:todo RSpec/InstanceVariable
require "tmpdir"

RSpec.describe Mittsu::GLTFExporter do
  let(:box) do
    box = Mittsu::Mesh.new(
      Mittsu::BoxGeometry.new(1.0, 1.0, 1.0)
    )
    box.name = "box"
    box
  end
  let(:exporter) { described_class.new }

  context "when exporting a file" do
    around do |example|
      Dir.mktmpdir do |dir|
        @filename = File.join(dir, "test.gltf")
        exporter.export(box, @filename)
        example.call
      end
    end

    it "creates a file" do
      expect(File.exist?(@filename)).to be true
    end

    it "file is JSON" do
      expect { JSON.parse(File.read(@filename)) }.not_to raise_exception
    end

    context "when the result is parsed" do
      let(:json) { JSON.parse(File.read(@filename)) }

      it "has a file version" do
        expect(json.dig("asset", "version")).to eq "2.0"
      end

      it "has a generator string" do
        expect(json.dig("asset", "generator")).to eq "Mittsu-GLTF"
      end

      it "has a default scene" do
        expect(json.dig("scene")).to eq 0
      end

      it "has an array of scenes" do
        expect(json.dig("scenes")).to eq [{"nodes" => [0]}]
      end

      it "has an array of nodes" do
        expect(json.dig("nodes")).to be_a Array
      end

      it "has an array of meshes" do
        expect(json.dig("meshes")).to be_a Array
      end

      it "has an array of buffers" do
        expect(json.dig("buffers")).to be_a Array
      end

      it "has an array of bufferViews" do
        expect(json.dig("bufferViews")).to be_a Array
      end

      it "has an array of accessors" do
        expect(json.dig("accessors")).to be_a Array
      end
    end
  end

  context "when exporting a single triangle mesh" do
    # These tests check that the gltf minimal example at
    # https://github.khronos.org/glTF-Tutorials/gltfTutorial/gltfTutorial_003_MinimalGltfFile.html
    # can be generated properly
    around do |example|
      geometry = Mittsu::Geometry.new
      geometry.vertices = [
        Mittsu::Vector3.new(0.0, 0.0, 0.0),
        Mittsu::Vector3.new(1.0, 0.0, 0.0),
        Mittsu::Vector3.new(0.0, 1.0, 0.0)
      ]
      geometry.faces = [
        Mittsu::Face3.new(0, 1, 2)
      ]
      triangle = Mittsu::Mesh.new(geometry, Mittsu::MeshBasicMaterial.new)
      Dir.mktmpdir do |dir|
        filename = File.join(dir, "test.gltf")
        exporter.export(triangle, filename)
        @json = JSON.parse(File.read(filename))
        example.call
      end
    end

    it "default scene is zero" do
      expect(@json.dig("scene")).to eq 0
    end

    it "scene zero includes node zero" do
      expect(@json.dig("scenes", 0)).to eq({"nodes" => [0]})
    end

    it "node zero has a single mesh" do
      expect(@json.dig("nodes", 0)).to eq({"mesh" => 0})
    end

    it "mesh zero references correct position attribute accessor" do
      expect(@json.dig("meshes", 0, "primitives", 0, "attributes", "POSITION")).to eq 1
    end

    it "mesh zero references correct face index accessor" do
      expect(@json.dig("meshes", 0, "primitives", 0, "indices")).to eq 0
    end

    it "accessor zero refers to integer triples for face indexes" do
      expect(@json.dig("accessors", 0)).to include({
        "componentType" => 5123,
        "count" => 3,
        "type" => "SCALAR"
      })
    end

    it "accessor zero includes ranges for face indexes" do
      expect(@json.dig("accessors", 0)).to include({
        "max" => [2],
        "min" => [0]
      })
    end

    it "accessor zero refers to bufferView zero" do
      expect(@json.dig("accessors", 0)).to include({
        "bufferView" => 0,
        "byteOffset" => 0
      })
    end

    it "accessor one refers to floating-point 3-vectors for vertex positions" do
      expect(@json.dig("accessors", 1)).to include({
        "componentType" => 5126,
        "count" => 3,
        "type" => "VEC3"
      })
    end

    it "accessor one includes value ranges for vertex positions" do
      expect(@json.dig("accessors", 1)).to include({
        "max" => [1.0, 1.0, 0.0],
        "min" => [0.0, 0.0, 0.0]
      })
    end

    it "accessor one refers to bufferView one" do
      expect(@json.dig("accessors", 1)).to include({
        "bufferView" => 1,
        "byteOffset" => 0
      })
    end

    it "bufferView zero is 6 contiguous bytes at the start of buffer zero" do
      expect(@json.dig("bufferViews", 0)).to include({
        "buffer" => 0,
        "byteOffset" => 0,
        "byteLength" => 6
      })
    end

    it "bufferView one is 3 floating-point 3-vectors (3*3*4 = 36 bytes) in buffer zero after the face set" do
      expect(@json.dig("bufferViews", 1)).to include({
        "buffer" => 0,
        "byteOffset" => 8,
        "byteLength" => 36
      })
    end

    it "buffer zero is 44 bytes long in total (6 + 2 padding + 36)" do
      puts @json.inspect
      expect(@json.dig("buffers", 0, "byteLength")).to eq 44
    end

    it "buffer zero includes a correctly base64 encoded data URI" do
      expect(@json.dig("buffers", 0, "uri")).to eq "data:application/octet-stream;base64,AAABAAIAAAAAAAAAAAAAAAAAAAAAAIA/AAAAAAAAAAAAAAAAAACAPwAAAAA="
    end
  end

  it "provides a #parse alias for export, for API-compatibility with THREE.js" do
    Dir.mktmpdir do |dir|
      filename = File.join(dir, "test.gltf")
      exporter.parse(box, filename)
      expect(File.exist?(filename)).to be true
    end
  end
end

# rubocop:enable RSpec/InstanceVariable
