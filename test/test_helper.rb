require 'minitest/autorun'
require 'minitest/pride'
require 'tempfile'

module PotatoTestHelper
  def run_potato(source)
    Tempfile.create(["test", ".potato"]) do |f|
      f.write(source)
      f.flush

      `./bin/potat #{f.path} --no-cache 2>&1`
    end
  end
end
