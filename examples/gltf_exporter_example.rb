$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "mittsu/gltf"

loader = Mittsu::OBJLoader.new
object = loader.load(File.expand_path("./mittsu.obj", File.dirname(__FILE__)))

exporter = Mittsu::GLTFExporter.new
exporter.export(object, File.expand_path("./mittsu-export.gltf", File.dirname(__FILE__)))
