module Potato
  class Compiler
    def self.compile(scope, ir, print: false)
      File.open("potat.o", "wb") do |f|
        write_ir(ir, f)
      end
    end

    def self.write_ir(ir, f)
      ir.each { |instruction| ir(instruction, f) }
    end

    def self.write(f, opcode, value = nil)
      f.write([opcode].pack("C"))
      f.write([value].pack("L>")) if value
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
        when NilClass
          write(f, 0x11)
        end
      when IR::LoadVar
        write(f, 0x04, instruction.index)
      when IR::LoadCaptured
        write(f, 0x0C, instruction.index)
      when IR::StoreVar
        write(f, 0x05, instruction.index)
      when IR::Add
        write(f, 0x02)
      when IR::Equality
        write(f, 0x07)
      when IR::NotEquality
        write(f, 0x15)
      when IR::GreaterThan
        write(f, 0x0D)
      when IR::LesserThan
        write(f, 0x12)
      when IR::GreaterEquals
        write(f, 0x13)
      when IR::LesserEquals
        write(f, 0x14)
      when IR::Or
        write(f, 0x0E)
      when IR::And
        write(f, 0x0F)
      when IR::Print
        write(f, 0x03)
      when IR::Call
        write(f, 0x09, instruction.target)
        f.write([instruction.arg_count].pack("L>")) 
      when IR::Return
        write(f, 0x0A)
      when IR::Jump
        write(f, 0x0B, instruction.target)
      when IR::JumpIfFalse
        write(f, 0x10, instruction.target)
      end
    end
  end
end