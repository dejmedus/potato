module PotatoVM
  class VM
    def self.read(bytes = 4)
      value = @bytecode[@pos, bytes].pack("C*").unpack1("L>")
      @pos += bytes
      value
    end

    def self.run
      @bytecode = File.binread("potat.o").bytes
      @pos = 0

      stack = []
      scopes = []
      locals = Array.new(100)

      until @pos >= @bytecode.size
        byte = @bytecode[@pos]
        @pos += 1

        case byte
        when 0x01 # number
          stack.push(read)
        when 0x02 # add
          stack.map!(&:to_s) if !stack.all? { |v| v.is_a?(Numeric) }
          value = stack.reduce(:+)
          stack.clear
          stack.push(value)
        when 0x03 # print
          puts stack.pop
        when 0x04 # variable
          index = read
          stack.push(locals[index])
          err "Unknown variable" if locals[index].nil?
        when 0x0C # captured variable
          index = read
          parent_locals = scopes.last[:locals]
          stack.push(parent_locals[index])
          err "Unknown captured variable" if parent_locals[index].nil?
        when 0x05 # assign
          index = read
          value = stack.pop
          locals[index] = value
        when 0x06 # string
          length = read
          value = @bytecode[@pos, length].pack("C*")
          @pos += length
          stack.push(value)
        when 0x07 # == operator
          right = stack.pop
          left = stack.pop
          stack.push(left == right)
        when 0x08 # boolean
          value = read
          stack.push(value == 1)
        when 0x09 # call
          target = read
          arg_count = read
          scopes.push({ locals: locals, call_site: @pos })
          locals = Array.new(100)
          args = stack.pop(arg_count)
          args.each_with_index { |arg, i| locals[i] = arg }
          @pos = target
        when 0x0A # return
          scope = scopes.pop
          locals = scope[:locals]
          @pos = scope[:call_site]
        when 0x0B # jump
          @pos = read
        end
      end
    end
  end
end

