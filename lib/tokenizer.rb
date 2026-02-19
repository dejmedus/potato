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
    def self.tokenize(line)
      line
        .strip
        .split(/\s+/)
        .reject(&:empty?)
        .map do |token|
          case token.downcase
          when "say"    then Token.new(:PRINT, nil)
          when "potato" then Token.new(:ADD, nil)
          when "is"     then Token.new(:EQUALS, nil)
          when /^\d+$/  then Token.new(:NUMBER, token.to_i)
          when /^[a-zA-Z_]\w*$/ then Token.new(:VARIABLE, token)
          else
            raise "Unknown token: #{token}"
          end
        end
    end
  end
end