class StepDefinition
	# The key is the REGEX and the value is the method to be called
	MATCHERS = {
		/I have a website named "(.*?)"$/ => :initialize_project,
		/I use "(.*?)" as a styling framework$/ => :add_twitter_bootstrap,
		/I have a "(.*?)" table$/ => :add_model,
		/the "(.*?)" table has a field named "(.*?)" with type "(.*?)"$/ => :add_column
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
			self.commit("Adding Twitter Bootstrap files", project_name)
		end
	end

	def self.add_model(regex, step, project_name)
		step =~ regex

		Dir.chdir("#{PROJECTS_PATH}/#{project_name}") do
			system("BUNDLE_GEMFILE=Gemfile bundle exec rails g model #{$1}")	

			# Commiting changes
			self.commit("Adding model #{$1}", project_name)
		end
	end

	def self.add_column(regex, step, project_name)
		step =~ regex

		Dir.chdir("#{PROJECTS_PATH}/#{project_name}") do
			system("BUNDLE_GEMFILE=Gemfile bundle exec rails g migration add_#{$2}_to_#{$1} #{$2}:#{$3}")	

			# Commiting changes
			self.commit("Adding column #{$2} to model #{$1}", project_name)
		end
	end

	def self.append_gem(gem_name, project_name)		
		File.open("Gemfile", "a") { |file| file.puts "gem '#{gem_name}'" }

		# Installing the gem
		system("BUNDLE_GEMFILE=Gemfile bundle install")
	end

	def self.commit(message, project_name)
		git = Git.open("./")
		git.add
		git.commit(message)
	end
end