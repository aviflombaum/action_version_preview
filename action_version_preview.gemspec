require_relative "lib/action_version_preview/version"

Gem::Specification.new do |spec|
  spec.name        = "action_version_preview"
  spec.version     = ActionVersionPreview::VERSION
  spec.authors     = [ "Avi Flombaum" ]
  spec.email       = [ "im@avi.nyc" ]
  spec.homepage    = "https://github.com/aviflombaum/action_version_preview"
  spec.summary     = "Preview multiple view variants side-by-side using Rails' built-in view variants."
  spec.description = "A zero-config Rails engine that leverages Rails' view variants to let you preview different versions of your UI simultaneously. Perfect for A/B design comparisons, UI iterations, and collecting feedback on redesigns."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aviflombaum/action_version_preview"
  spec.metadata["changelog_uri"] = "https://github.com/aviflombaum/action_version_preview/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.1.0"

  spec.add_dependency "rails", ">= 7.0", "< 9.0"
end
