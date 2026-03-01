module Potato
  class Compiler
    def self.compile(scope, ir, print: false)
    if print
      ir.each_with_index { |instruction, i| puts "  #{i}: #{instruction.inspect}" }
    end

      File.open("potat.o", "wb") do |f|
        write_ir(ir, f)
      end
    end

    def self.write_ir(ir, f)
      ir.each { |instruction| ir(instruction, f) }
    end

    def self.ir(instruction, f)
      case instruction
      when IR::Push
        case instruction.value
        when Integer
          f.write([0x01].pack("C"))
          f.write([instruction.value].pack("L>"))
        when String
          f.write([0x06].pack("C"))
          f.write([instruction.value.bytesize].pack("L>"))
          f.write(instruction.value)
        when TrueClass, FalseClass
          f.write([0x08].pack("C"))
          f.write([instruction.value ? 1 : 0].pack("L>"))
        end
      when IR::LoadVar
        f.write([0x04].pack("C"))
        f.write([instruction.index].pack("L>"))
      when IR::StoreVar
        f.write([0x05].pack("C"))
        f.write([instruction.index].pack("L>"))
      when IR::Add
        f.write([0x02].pack("C"))
      when IR::Equality
        f.write([0x07].pack("C"))
      when IR::Print
        f.write([0x03].pack("C"))
      when IR::Call
        f.write([0x09].pack("C"))
        f.write([instruction.target].pack("L>"))
        f.write([instruction.arg_count].pack("L>"))
      when IR::Return
        f.write([0x0A].pack("C"))
      when IR::Jump
        f.write([0x0B].pack("C"))
        f.write([instruction.target].pack("L>"))
      end
    end
  end
end