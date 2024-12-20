$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "mittsu/gltf"

loader = Mittsu::OBJLoader.new
object = loader.load(File.expand_path("./gltf.obj", File.dirname(__FILE__)))

exporter = Mittsu::GLTFExporter.new
exporter.export(object, File.expand_path("./export.gltf", File.dirname(__FILE__)))

exporter.export(object, File.expand_path("./export.glb", File.dirname(__FILE__)), mode: :binary)
