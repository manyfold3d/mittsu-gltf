require "jbuilder"
require "base64"

module Mittsu
  module ProgressiveGLTFExporter
    def add_progressive_mesh(mesh)
      # Add extension to used
      # but not required, as the base mesh can be rendered without the vertex split stream
      @extensions_used << "MANYFOLD_mesh_progressive"

      # First, add the base mesh in the standard way
      index = add_mesh(mesh, mode: :binary)

      offset = @binary_buffer.length
      mesh.vertex_splits.each do |vsplit|
        # Add vertices and pad
        @binary_buffer += [vsplit.vertex, vsplit.left, vsplit.right].pack("L<*")
        @binary_buffer += Array.new(padding_required(@binary_buffer, stride: 4), 0).pack("C*")
        # Add displacement vector
        @binary_buffer += vsplit.displacement.elements.pack("f*")
        @binary_buffer += Array.new(padding_required(@binary_buffer, stride: 4), 0).pack("C*")
      end
      length = @binary_buffer.length - offset
      # Update buffer length
      buffer_index = @buffers.length - 1
      @buffers[buffer_index][:byteLength] = @binary_buffer.length

      stride = length / mesh.vertex_splits.length

      # Create the pair of interleaved accessors

      min, max = progressive_vertex_bounds(mesh)
      progressive_vertex_accessor_index = add_accessor(
        buffer_view: add_buffer_view(
          buffer: buffer_index,
          offset: offset,
          length: length,
          byte_stride: stride,
          target: :array_buffer
        ),
        component_type: :unsigned_int,
        count: mesh.vertex_splits.count,
        type: "VEC3",
        min: min,
        max: max
      )

      min, max = progressive_displacement_bounds(mesh)
      progressive_displacement_accessor_index = add_accessor(
        buffer_view: add_buffer_view(
          buffer: buffer_index,
          offset: offset + 12,
          length: length - 12,
          byte_stride: stride,
          target: :array_buffer
        ),
        component_type: :float,
        count: mesh.vertex_splits.count,
        type: "VEC3",
        min: min,
        max: max
      )

      # Add in mesh extension data
      @meshes[index][:extensions] = {
        MANYFOLD_mesh_progressive: {
          attributes: {
            POSITION: progressive_displacement_accessor_index
          },
          indices: progressive_vertex_accessor_index
        }
      }

      index
    end

    private

    def progressive_vertex_bounds(mesh)
      vertex = mesh.vertex_splits.map(&:vertex).minmax
      left = mesh.vertex_splits.map(&:left).minmax
      right = mesh.vertex_splits.map(&:right).minmax
      [
        [vertex[0], left[0], right[0]],
        [vertex[1], left[1], right[1]]
      ]
    end

    def progressive_displacement_bounds(mesh)
      x = mesh.vertex_splits.map { |vsplit| vsplit.displacement.x }.minmax
      y = mesh.vertex_splits.map { |vsplit| vsplit.displacement.y }.minmax
      z = mesh.vertex_splits.map { |vsplit| vsplit.displacement.z }.minmax
      [
        [x[0], y[0], z[0]],
        [x[1], y[1], z[1]]
      ]
    end
  end
end
