require 'minitest/autorun'
require 'minitest/pride'
require 'tempfile'

module PotatoTestHelper
  def run_potato(source)
    Tempfile.create(['test', '.potato']) do |f|
      f.write(source)
      f.flush
      
      `./bin/potato #{f.path} 2>&1`
      `./bin/potato_vm 2>&1`
    end
  end
end
