class StepDefinition
	# The key is the REGEX and the value is the method to be called
	MATCHERS = {
		/test$/ => :testing,
		/test2$/ => :testing2
	}

	# Calls the method that matches the step
	def self.match(step)
		self.method_for(step)
	end

	private

	# Find a matching method for a step
	def self.method_for(step)
		self.send(MATCHERS[MATCHERS.keys.find { |keys| keys =~ step }])
	end

	###############################
	# Defining the step definitions
	###############################
	def self.testing
		p "Test"
	end

	def self.testing2
		p "Test 2"
	end
end