require "jbuilder"
require "base64"
require_relative "progressive_exporter"

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

    GPU_BUFFER_TYPES = {
      array_buffer: 34962,
      element_array_buffer: 34963
    }

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
      # Include progressive export capability if mesh analysis gem is loaded
      if defined?(Mittsu::MeshAnalysis::ProgressiveMesh)
        self.class.include ProgressiveGLTFExporter
      end
      @node_indexes = []
      @nodes = []
      @buffers = []
      @meshes = []
      @buffer_views = []
      @accessors = []
      @binary_buffer = nil
    end

    def export(object, filename, mode: :ascii)
      initialize
      object.traverse do |obj|
        if defined?(Mittsu::MeshAnalysis::ProgressiveMesh) && obj.is_a?(Mittsu::MeshAnalysis::ProgressiveMesh)
          @node_indexes << add_progressive_mesh(obj)
        elsif obj.is_a? Mittsu::Mesh
          @node_indexes << add_mesh(obj, mode: mode)
        end
      end
      json = Jbuilder.new do |json|
        json.asset do
          json.generator "Mittsu-GLTF"
          json.version "2.0"
        end
        json.scene 0
        json.scenes [{
          nodes: @node_indexes
        }]
        json.nodes { json.array! @nodes }
        json.meshes { json.array! @meshes }
        json.buffers { json.array! @buffers }
        json.bufferViews { json.array! @buffer_views }
        json.accessors { json.array! @accessors }
      end.target!
      case mode
      when :ascii
        File.write(filename, json)
      when :binary
        File.open(filename, "wb") do |file|
          size = 12 +
            8 + json.length + padding_required(json, stride: 4) +
            8 + @binary_buffer.length + padding_required(@binary_buffer, stride: 4)
          file.write("glTF")
          file.write([2, size].pack("L<*"))
          write_chunk(file, :json, json)
          write_chunk(file, :binary, @binary_buffer)
        end
      else
        raise ArgumentError "Invalid output mode #{mode}"
      end
    end

    # Parse is here for consistency with THREE.js's weird naming of exporter methods
    alias_method :parse, :export

    private

    def write_chunk(file, type, data)
      pad = padding_required(data, stride: 4)
      file.write([data.length + pad].pack("L<*"))
      case type
      when :json
        file.write("JSON")
      when :binary
        file.write("BIN\0")
      else
        raise ArgumentError.new("Invalid chunk type: #{type}")
      end
      file.write data
      file.write(Array.new(pad, (type == :json) ? 32 : 0).pack("C*")) # Space characters for JSON, null otherwise
    end

    def add_mesh(mesh, mode:)
      # Pack faces into an array
      pack_string = (mesh.geometry.faces.count > (2**16)) ? "L<*" : "S<*"
      faces = mesh.geometry.faces.map { |x| [x.a, x.b, x.c] }
      data = faces.flatten.pack(pack_string)
      # Add bufferView and accessor for faces
      face_accessor_index = add_accessor(
        buffer_view: add_buffer_view(
          buffer: @buffers.count,
          offset: 0,
          length: data.length,
          target: :element_array_buffer
        ),
        component_type: (mesh.geometry.faces.count > (2**16)) ? :unsigned_int : :unsigned_short,
        count: mesh.geometry.faces.count * 3,
        type: "SCALAR",
        min: 0,
        max: mesh.geometry.vertices.count - 1
      )
      # Add padding to get to integer multiple of float size
      padding = padding_required(data, stride: 4)
      data += Array.new(padding, 0).pack("C*")
      # Pack vertices in as floats
      offset = data.length
      vertices = mesh.geometry.vertices.map(&:elements)
      data += vertices.flatten.pack("f*")
      # Add bufferView and accessor for vertices
      mesh.geometry.compute_bounding_box
      vertex_accessor_index = add_accessor(
        buffer_view: add_buffer_view(
          buffer: @buffers.count,
          offset: offset,
          length: data.length - offset,
          target: :array_buffer
        ),
        component_type: :float,
        count: mesh.geometry.vertices.count,
        type: "VEC3",
        min: mesh.geometry.bounding_box.min.elements,
        max: mesh.geometry.bounding_box.max.elements
      )
      # Encode and store in buffers
      @binary_buffer = data
      @buffers << ((mode == :ascii) ? {
        uri: "data:application/octet-stream;base64," + Base64.strict_encode64(@binary_buffer),
        byteLength: @binary_buffer.length
      } : {
        byteLength: @binary_buffer.length
      })
      # Add mesh
      mesh_index = @meshes.count
      @meshes << {
        "primitives" => [
          {
            "attributes" => {
              "POSITION" => vertex_accessor_index
            },
            "indices" => face_accessor_index
          }
        ]
      }
      # Add node
      index = @nodes.count
      @nodes << {
        mesh: mesh_index
      }
      index
    end

    def add_buffer_view(buffer:, offset:, length:, target: nil)
      # Check args
      raise ArgumentError.new("invalid GPU buffer target: #{target}") unless target.nil? || GPU_BUFFER_TYPES.key?(target)
      index = @buffer_views.count
      @buffer_views << {
        buffer: buffer,
        byteOffset: offset,
        byteLength: length,
        target: GPU_BUFFER_TYPES[target]
      }
      index
    end

    def add_accessor(buffer_view:, component_type:, count:, type:, min:, max:, offset: 0)
      # Check args
      raise ArgumentError.new("invalid component type: #{component_type}") unless COMPONENT_TYPES.key?(component_type)
      raise ArgumentError.new("invalid element type: #{type}") unless ELEMENT_TYPES.include?(type)
      # Add data
      index = @accessors.count
      @accessors << {
        bufferView: buffer_view,
        byteOffset: offset,
        componentType: COMPONENT_TYPES[component_type],
        count: count,
        type: type,
        min: Array(min),
        max: Array(max)
      }
      index
    end

    def padding_required(data, stride: 4)
      (stride - (data.length % stride)) % stride
    end
  end
end
