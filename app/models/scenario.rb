class Scenario < WebifyModel
	# Returns the steps of the scenario
	def lines
		self.steps.map { |step| Step.new(step) }
	end
end