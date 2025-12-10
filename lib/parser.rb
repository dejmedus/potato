module Potato
  class Parser
    def self.parse(source)
      source.lines.each do |line|
        tokens = Tokenizer.tokenize_line(line)
        next if tokens.empty?
        run_line(tokens)
      end
    end

    def self.run_line(tokens)
      return unless tokens[0]&.type == :SAY
      return unless tokens.any? { |t| t.type == :ADD }

      numbers = tokens.select { |t| t.type == :NUMBER }.map(&:value)
      return unless numbers.size >= 2

      result = numbers.reduce(0, :+)
      puts result
    end
  end
end