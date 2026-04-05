# frozen_string_literal: true

# rake bundle   builds playground
# rake test     runs tests


desc "Run tests"
task :test do
  sh "ruby test/potato_test.rb"
end

desc "Build playground"
task :bundle do
  build_bundle
end

BUNDLE_OUT = "playground/potato_bundle.rb"
LIB_DIR    = "lib"
ENTRY      = File.join(LIB_DIR, "potato.rb")
def build_bundle
  require_relative_re = /^\s*require_relative\s+['"](.+)['"]\s*$/

  entry_src = File.read(ENTRY)
  ordered_requires = entry_src
    .each_line
    .filter_map { |line| line.match(require_relative_re)&.captures&.first }

  files_in_order = ordered_requires.map { |r| File.join(LIB_DIR, "#{r}.rb") } + [ENTRY]

  header = <<~RUBY
    # frozen_string_literal: true
    # AUTO-GENERATED — do not edit by hand.
    # Run `rake bundle` to regenerate from lib/*.rb
    # Generated: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}

  RUBY

  parts = files_in_order.map do |path|
    abort "Missing file: #{path}" unless File.exist?(path)
    src = File.read(path)
    # Strip require_relative lines — everything is inlined
    src = src.gsub(require_relative_re, "")
    "# ── #{File.basename(path)} #{"─" * [0, 74 - File.basename(path).length].max}\n\n#{src.strip}\n"
  end

  FileUtils.mkdir_p(File.dirname(BUNDLE_OUT))
  File.write(BUNDLE_OUT, header + parts.join("\n\n"))

  size_kb = (File.size(BUNDLE_OUT) / 1024.0).round(1)
  puts "✓ Bundle written → #{BUNDLE_OUT} (#{size_kb} KB, #{files_in_order.length} files)"
end
