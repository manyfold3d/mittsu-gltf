require "jbuilder"

module Mittsu
  class GLTFExporter
    def initialize(options = {})
    end

    def export(_object, filename)
      File.write(
        filename,
        Jbuilder.new do |json|
          json.asset do
            json.generator "Mittsu-GLTF"
            json.version "2.0"
          end
          json.scene 0
          json.scenes [{
            nodes: []
          }]
        end.target!
      )
    end

    # Parse is here for consistency with THREE.js's weird naming of exporter methods
    alias_method :parse, :export
  end
end
