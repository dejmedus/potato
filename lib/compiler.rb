module Potato
  class Compiler
    def self.compile(ast, scope, ir, function_table, print: false)
      if print
        ir.each_with_index { |instruction, i| puts "  #{i}: #{instruction.inspect}" }
        function_table.each { |name, index| puts "  #{name} #{index}" }
      end

      File.open("potat.o", "wb") do |f|
        write_symbol_table(scope.symbol_table, f)
        write_function_table(function_table, f)
        write_ir(ir, f)
      end
    end

    def self.write_ir(ir, f)
      ir.each { |instruction| ir(instruction, f) }
    end

    def self.write_function_table(function_table, f)
      f.write([function_table.size].pack("L>"))

      function_table.each do |var, index|
        f.write([var.bytesize].pack("C"))
        f.write(var)
        f.write([index].pack("L>"))
      end
    end

    def self.write_symbol_table(symbol_table, f)
      f.write([symbol_table.size].pack("L>"))

      symbol_table.each do |var, index|
        f.write([var.bytesize].pack("C"))
        f.write(var)
        f.write([index].pack("L>"))
      end
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
        f.write([instruction.name.bytesize].pack("C"))
        f.write(instruction.name)
        f.write([instruction.arg_count].pack("L>"))
      when IR::Return
        f.write([0x0A].pack("C"))
      end
    end
  end
end
