class StepDefinition
	# The key is the REGEX and the value is the method to be called
	MATCHERS = {
		/I have a website named "(.*?)"$/ => :initialize_project,
		/I use "(.*?)" as a styling framework$/ => :add_twitter_bootstrap
	}

	PROJECTS_PATH = "../webify_projects"

	# Calls the method that matches the step
	def self.match(step, project_name)
		self.method_for(step, project_name)
	end

	private

	# Find a matching method for a step
	def self.method_for(step, project_name)
		matching_regex = MATCHERS.keys.find { |keys| keys =~ step }

    self.send(MATCHERS[matching_regex], matching_regex, step, project_name)
	end

	###############################
	# Defining the step definitions
	###############################
	def self.initialize_project(regex, step, project_name)
		Dir.chdir(PROJECTS_PATH) do
			step =~ regex
			`rails new #{$1.downcase.underscore}`
		end

		# Initialize Git repo and commit 
		Dir.chdir("../webify_projects/#{project_name}") do
			git = Git.init
			git.add
			git.commit("Initial commit")
		end
	end

	def self.add_twitter_bootstrap(regex, step, project_name)
		Dir.chdir("#{PROJECTS_PATH}/#{project_name}") do
			self.append_gem("twitter-bootstrap-rails", project_name)
			
			# Generating the Twitter Bootstrap layout files
			system("BUNDLE_GEMFILE=Gemfile bundle exec rails g bootstrap:layout application fluid -f")

			# Commiting changes
			git = Git.open("./")
			git.add
			git.commit("Adding Twitter Bootstrap files")
		end
	end

	def self.append_gem(gem_name, project_name)		
		File.open("Gemfile", "a") { |file| file.puts "gem '#{gem_name}'" }
		system("BUNDLE_GEMFILE=Gemfile bundle install")
	end
end