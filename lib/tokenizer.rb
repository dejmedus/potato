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
          when /^\d+$/  then Token.new(:NUMBER, token.to_i)
          else
            raise "Unknown token: #{token}"
          end
        end
    end
  end
end