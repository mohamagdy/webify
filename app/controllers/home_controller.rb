class HomeController < ApplicationController
  # GET /
  def index
  end

  # POST /upload
  def upload
  	features = Parser.parse(params[:file].path)

  	features.each do |feature|
	  	feature.scenarios.each do |scenario|
	  		scenario.lines.each do |step|
	  			StepDefinition.match(step.name, "basic")
	  		end
	  	end
  	end

  	redirect_to root_path
  end
end
