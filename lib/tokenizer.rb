module Potato
  class Token
    attr_reader :type, :value

    def initialize(type, value)
      @type = type
      @value = value
    end

    def to_s
      "#{type} #{value}" 
    end
  end

  class Tokenizer
    def self.tokenize(source)
      tokens = []
      source.split(/\s+/).each do |token|
        case token
        when "say"
          tokens << Token.new(:SAY, nil)
        when "potato"
          tokens << Token.new(:ADD, nil)
        else
          tokens << Token.new(:NUMBER, token.to_i)
        end
      end
      tokens
    end
  end
end