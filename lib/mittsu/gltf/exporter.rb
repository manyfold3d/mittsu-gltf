require "jbuilder"
require "base64"

module Mittsu
  class GLTFExporter
    COMPONENT_TYPES = {
      # 8 bit
      byte: 5120,
      unsigned_byte: 5121,
      # 16 bit
      short: 5122,
      unsigned_short: 5123,
      # 32 bit
      unsigned_int: 5125,
      float: 5126
    }.freeze

    ELEMENT_TYPES = [
      "SCALAR",
      "VEC2",
      "VEC3",
      "VEC4",
      "MAT2",
      "MAT3",
      "MAT4"
    ].freeze

    def initialize(options = {})
      @buffers = []
      @meshes = {}
      @buffer_views = []
      @accessors = []
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
          json.accessors { json.array! @accessors }
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
      # Add bufferView and accessor for faces
      face_accessor_index = add_accessor(
        buffer_view: add_buffer_view(buffer: index, offset: 0, length: data.length),
        component_type: (mesh.geometry.faces.count > (2**16)) ? COMPONENT_TYPES[:unsigned_int] : COMPONENT_TYPES[:unsigned_short],
        count: mesh.geometry.faces.count * 3,
        type: "SCALAR",
        min: 0,
        max: mesh.geometry.vertices.count - 1
      )
      # Add padding to get to integer multiple of float size
      padding = 4 - (data.length % 4)
      data += Array.new(padding, 0).pack("C*")
      # Pack vertices in as floats
      offset = data.length
      vertices = mesh.geometry.vertices.map(&:elements)
      data += vertices.flatten.pack("f*")
      # Add bufferView and accessor for vertices
      mesh.geometry.compute_bounding_box
      vertex_accessor_index = add_accessor(
        buffer_view: add_buffer_view(buffer: index, offset: offset, length: data.length - offset),
        component_type: COMPONENT_TYPES[:float],
        count: mesh.geometry.vertices.count,
        type: "VEC3",
        min: mesh.geometry.bounding_box.min.elements,
        max: mesh.geometry.bounding_box.max.elements
      )
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

    def add_accessor(buffer_view:, component_type:, count:, type:, min:, max:, offset: 0)
      # Check args
      raise ArgumentError.new("invalid component type: #{component_type}") unless COMPONENT_TYPES.values.include?(component_type)
      raise ArgumentError.new("invalid element type: #{type}") unless ELEMENT_TYPES.include?(type)
      # Add data
      index = @accessors.count
      @accessors << {
        bufferView: buffer_view,
        byteOffset: offset,
        componentType: component_type,
        count: count,
        type: type,
        min: Array(min),
        max: Array(max)
      }
      index
    end
  end
end
