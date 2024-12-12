require "jbuilder"
require "base64"

module Mittsu
  class GLTFExporter
    def initialize(options = {})
      @buffers = []
      @meshes = {}
      @buffer_views = []
    end

    def export(object, filename)
      object.traverse do |obj|
        if obj.is_a? Mittsu::Mesh
          @meshes[obj.uuid] ||= {}
          @meshes[obj.uuid][:buffer_index] = add_buffer(obj)
        end
      end
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
          json.nodes []
          json.buffers { json.array! @buffers }
          json.bufferViews { json.array! @buffer_views }
        end.target!
      )
    end

    # Parse is here for consistency with THREE.js's weird naming of exporter methods
    alias_method :parse, :export

    private

    def add_buffer(mesh)
      index = @buffers.count
      # Pack faces into an array
      pack_string = (mesh.geometry.faces.count > (2**16)) ? "L<*" : "S<*"
      faces = mesh.geometry.faces.map { |x| [x.a, x.b, x.c] }
      data = faces.flatten.pack(pack_string)
      # Add bufferView for faces
      @meshes[mesh.uuid][:face_buffer_view_index] = add_buffer_view(buffer: index, offset: 0, length: data.length)
      # Add padding to get to integer multiple of float size
      padding = 4 - (data.length % 4)
      data += Array.new(padding, 0).pack("C*")
      # Pack vertices in as floats
      offset = data.length
      vertices = mesh.geometry.vertices.map(&:elements)
      data += vertices.flatten.pack("f*")
      # Add bufferView for faces
      @meshes[mesh.uuid][:vertex_buffer_view_index] = add_buffer_view(buffer: index, offset: offset, length: data.length - offset)
      # Encode and store in buffers
      @buffers << {
        uri: "data:application/octet-stream;base64," + Base64.encode64(data).strip,
        byteLength: data.length
      }
      index
    end

    def add_buffer_view(buffer:, offset:, length:)
      index = @buffer_views.count
      @buffer_views << {
        buffer: buffer,
        byteOffset: offset,
        byteLength: length
      }
      index
    end
  end
end
