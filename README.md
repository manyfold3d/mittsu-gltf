# Mittsu: GLTF
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

## About

This code was originally written for [Manyfold](https://manyfold.app), supported by funding from [NLNet](https://nlnet.nl) and [NGI Zero](https://ngi.eu/ngi-projects/ngi-zero/).
