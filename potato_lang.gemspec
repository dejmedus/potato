Gem::Specification.new do |s|
  s.name        = "potato_lang"
  s.version     = "0.0.0"
  s.summary     = ""
  s.description = ""
  s.authors     = ["Julia B"]
  s.email       = "hi@juliab.dev"
  s.homepage = "https://github.com/dejmedus/potato"
  s.metadata["source_code_uri"] = s.homepage
  s.files = Dir.glob("lib/**/*.rb") + Dir.glob("bin/*")
  s.required_ruby_version = ">= 3.0"
  s.license       = "MIT"
  s.executables = ["potat"]
  s.bindir      = "bin"
end
