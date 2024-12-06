RSpec.describe Mittsu::GLTFExporter do
  let(:box) {
    box = Mittsu::Mesh.new(
      Mittsu::BoxGeometry.new(1.0, 1.0, 1.0)
    )
    box.name = "box"
    box
  }
  let (:exporter) { described_class.new }

  it "can create a valid GLTF model file"
end
