require 'gherkin/parser/parser'
require 'gherkin/formatter/json_formatter'
require 'stringio'

class Parser
	def self.parse(file)
		io = StringIO.new
		formatter = Gherkin::Formatter::JSONFormatter.new(io)
		parser = Gherkin::Parser::Parser.new(formatter)

	  path = File.expand_path(file)
	  parser.parse(IO.read(path), path, 0)

		formatter.done

		JSON.parse(io.string).map { |feature| Feature.new(feature, recurse_over_arrays: true) }
	end  
end	