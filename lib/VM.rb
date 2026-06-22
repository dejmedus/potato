# frozen_string_literal: true

module PotatoVM
  class VM
    # otherwise we can't compare 
    # to real nil values
    None = Object.new
    def None.to_s = "none"

    Frame = Struct.new(:cur, :jump_loc, :prev)

    def initialize(bytecode)
      @bytecode = bytecode.bytes
      @pos = 0
      @stack = []
      @frames = []
      @cur = 0 
      @exit = false
    end

    def run
      step until @exit
    end

    def step
      return self if @exit

      byte = @bytecode[@pos]
      @pos += 1
      execute(byte)
      @exit = @pos >= @bytecode.size
      self
    end

    private

    def read(bytes = 4)
      value = @bytecode[@pos, bytes].pack("C*").unpack1("L>")
      @pos += bytes
      value
    end

    def operation(&op)
      right = @stack.pop
      left = @stack.pop
      @stack.push(op.call(left, right))
    end

    def execute(byte)
      case byte
      when 0x01 # number
        @stack.push(read)
      when 0x02 # add
        right = @stack.pop
        left = @stack.pop
        if !left.is_a?(Numeric) || !right.is_a?(Numeric)
          left = left.to_s
          right = right.to_s
        end
        @stack.push(left + right)
      when 0x03 # print
        puts @stack.pop
      when 0x04 # variable
        index = read
        val = @stack[@cur + index]
        err "Unknown variable" if val.nil?
        @stack.push(val)
      when 0x0C # captured variable
        index = read
        caller_cur = @frames.last&.prev || 0
        val = @stack[caller_cur + index]
        err "Unknown captured variable" if val.nil?
        @stack.push(val)
      when 0x05 # assign
        index = read
        value = @stack.pop
        @stack[@cur + index] = value
      when 0x06 # string
        length = read
        value = @bytecode[@pos, length].pack("C*")
        @pos += length
        @stack.push(value)
      when 0x07 then operation { |l, r| l == r }
      when 0x15 then operation { |l, r| l != r }
      when 0x0E then operation { |l, r| l || r }
      when 0x0F then operation { |l, r| l && r }
      when 0x0D then operation { |l, r| l > r }
      when 0x12 then operation { |l, r| l < r }
      when 0x13 then operation { |l, r| l >= r }
      when 0x14 then operation { |l, r| l <= r }
      when 0x08 # boolean
        value = read
        @stack.push(value == 1)
      when 0x11 # none
        @stack.push(None)
      when 0x09 # call
        target = read
        arg_count = read
        args = @stack.pop(arg_count)
        @frames.push(Frame.new(@cur, @pos, @cur))
        @cur = @stack.size
        args.each { |a| @stack.push(a) }
        @pos = target
      when 0x0A # return
        return_value = @stack.pop
        frame = @frames.pop
        @stack.slice!(frame.cur..)
        @cur = frame.prev
        @pos = frame.jump_loc
        @stack.push(return_value)
      when 0x0B # jump
        @pos = read
      when 0x10 # jump if false
        target = read
        falsey = [false, None]
        @pos = target if falsey.include?(@stack.pop)
      end
    end
  end
end