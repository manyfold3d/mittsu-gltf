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
        expect(json.dig("scenes")).to eq [{"nodes" => []}]
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

  it "provides a #parse alias for export, for API-compatibility with THREE.js" do
    Dir.mktmpdir do |dir|
      filename = File.join(dir, "test.gltf")
      exporter.parse(box, filename)
      expect(File.exist?(filename)).to be true
    end
  end
end
