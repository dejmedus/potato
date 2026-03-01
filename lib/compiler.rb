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

    def self.write(f, opcode, value = 0)
      f.write([opcode].pack("C"))
      f.write([value].pack("L>"))
    end

    def self.ir(instruction, f)
      case instruction
      when IR::Push
        case instruction.value
        when Integer
          write(f, 0x01, instruction.value)
        when String
          write(f, 0x06, instruction.value.bytesize)
          f.write(instruction.value)
        when TrueClass, FalseClass
          write(f, 0x08, instruction.value ? 1 : 0)
        end
      when IR::LoadVar
        write(f, 0x04, instruction.index)
      when IR::StoreVar
        write(f, 0x05, instruction.index)
      when IR::Add
        write(f, 0x02)
      when IR::Equality
        write(f, 0x07)
      when IR::Print
        write(f, 0x03)
      when IR::Call
        write(f, 0x09)
        write(f, instruction.target)
        write(f, instruction.arg_count)
      when IR::Return
        write(f, 0x0A)
      when IR::Jump
        write(f, 0x0B)
        write(f, instruction.target)
      end
    end
  end
end