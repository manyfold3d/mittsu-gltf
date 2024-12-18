require_relative "lib/mittsu/gltf/version"

Gem::Specification.new do |spec|
  spec.name = "mittsu-gltf"
  spec.version = Mittsu::GLTF::VERSION
  spec.authors = ["James Smith"]
  spec.email = ["james@floppy.org.uk"]
  spec.homepage = "https://github.com/manyfold3d/mittsu-gltf"
  spec.summary = "GLTF file support for Mittsu"
  spec.description = "GLTF file support for Mittsu"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/manyfold3d/mittsu-gltf"
  spec.metadata["changelog_uri"] = "https://github.com/manyfold3d/mittsu-gltf/releases"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["lib/**/*", "LICENSE
    ", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = "~> 3.1"

  spec.add_dependency "mittsu", "~> 0.4"
  spec.add_dependency "jbuilder", "~> 2.13"

  spec.add_development_dependency "rake", "~> 13.2"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "standard", "~> 1.41"
  spec.add_development_dependency "rubocop-rspec", "~> 3.2"
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
