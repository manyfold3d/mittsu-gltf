$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "mittsu/gltf"
begin
  require "mittsu/mesh_analysis"
rescue LoadError
  puts "This example requires the mittsu-mesh_analysis gem, please install it."
  return
end

loader = Mittsu::OBJLoader.new
object = loader.load(File.expand_path("./mittsu.obj", File.dirname(__FILE__)))
object.traverse do |x|
  if x.is_a? Mittsu::Mesh
    object = x
    break
  end
end

progressive = Mittsu::MeshAnalysis::ProgressiveMesh.new(object.geometry, object.material)
progressive.progressify ratio: 0.75

exporter = Mittsu::GLTFExporter.new
exporter.export(progressive, File.expand_path("./progressive-export.glb", File.dirname(__FILE__)), mode: :binary)
