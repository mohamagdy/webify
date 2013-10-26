class Feature < WebifyModel
	# Returns the scenarios of the feature
	def scenarios
		self.elements.map { |scenario| Scenario.new(scenario) }
	end
end