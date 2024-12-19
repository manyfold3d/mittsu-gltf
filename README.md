# Mittsu: GLTF

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/manyfold3d/mittsu-gltf/build-workflow.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/fcd3adbcc0c9846ee219/maintainability)](https://codeclimate.com/github/manyfold3d/mittsu-gltf/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/fcd3adbcc0c9846ee219/test_coverage)](https://codeclimate.com/github/manyfold3d/mittsu-gltf/test_coverage)
![Libraries.io dependency status for latest release](https://img.shields.io/librariesio/release/rubygems/mittsu-gltf)


![GitHub Release](https://img.shields.io/github/v/release/manyfold3d/mittsu-gltf)
![Gem Downloads (for latest version)](https://img.shields.io/gem/dtv/mittsu-gltf)
![Dependent repos (via libraries.io)](https://img.shields.io/librariesio/dependent-repos/rubygems/mittsu-gltf)

GLTF support for [Mittsu](https://github.com/danini-the-panini/mittsu).

## Installation

Just install:

`bundle add mittsu-gltf`

Then require in your code:

`require 'mittsu/gltf'`

## Usage

Currently this gem just includes an exporter. Loading GLTF files might happen at some point.

```
exporter = Mittsu::GLTFExporter.new
exporter.export(object, "output.gltf")
```

You can also write binary files for simple single-mesh models:

```
exporter.export(object, "output.glb", mode: :binary)
```

## Progressive Meshes

The binary GLTF exporter can create "progressive meshes" using the proposed
[`MANYFOLD_mesh_progressive` GLTF extension](https://github.com/manyfold3d/glTF/tree/MANYFOLD_mesh_progressive/extensions/2.0/Vendor/MANYFOLD_mesh_progressive#readme). If you want to create these sort of meshes, you will need to install
the `mittsu-mesh_analysis` gem and create a `Mittsu::MeshAnalysis::ProgressiveMesh` object, which you can
then pass to `export` in the same way as above.

## About

This code was originally written for [Manyfold](https://manyfold.app), supported by funding from [NLNet](https://nlnet.nl) and [NGI Zero](https://ngi.eu/ngi-projects/ngi-zero/).
