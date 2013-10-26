class StepDefinition
	# The key is the REGEX and the value is the method to be called
	MATCHERS = {
		/I have a website named "(.*?)"$/ => :initialize_project,
		/I use "(.*?)" as a styling framework$/ => :add_twitter_bootstrap,
		/I have a "(.*?)" table$/ => :add_model,
		/the "(.*?)" table has a field named "(.*?)" with type "(.*?)"$/ => :add_column,
		/I have an authentication page$/ => :add_devise,
		/I have a registration page$/ => :add_devise,
		/I have the following pages/ => :add_pages,
		/I have a main menu with the following links/ => :add_menu_items
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
			system("BUNDLE_GEMFILE=Gemfile bundle exec rails g bootstrap:install static")
			system("BUNDLE_GEMFILE=Gemfile bundle exec rails g bootstrap:layout application fluid -f")

			# Update the HTML body field
			body_template = ERB.new(IO.read("#{Rails.root}/templates/body.html.erb"))
			layout = File.read("app/views/layouts/application.html.erb")
			layout.gsub!(/<body>(.*)<\/body>/mi, body_template.result(binding))

			File.open("app/views/layouts/application.html.erb", "w+") { |file| file.puts layout }

			File.open("app/assets/stylesheets/bootstrap_and_overrides.css", "a") { |file| file.puts "body { padding-top: 60px; }" }

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

	def self.add_devise(regex, step, project_name)
		step =~ regex

		Dir.chdir("#{PROJECTS_PATH}/#{project_name}") do	
			self.append_gem("devise", project_name)
		
			# # Generating the Devise files
			system("BUNDLE_GEMFILE=Gemfile bundle exec rails generate devise:install -f")
			system("BUNDLE_GEMFILE=Gemfile bundle exec rails generate devise user")

			# # Commiting changes
			self.commit("Adding Devise files", project_name)
		end		
	end

	def self.add_pages(regex, step, project_name)
		Dir.chdir("#{PROJECTS_PATH}/#{project_name}") do
			page_names = step.scan(/"([^"]*)"/).flatten

			page_names.each do |page|
				system("BUNDLE_GEMFILE=Gemfile bundle exec rails g controller #{page.downcase.underscore} index")
			end

			# Commiting changes
			self.commit("Adding #{page_names.join(' ')} pages", project_name)
		end
	end

	def self.add_menu_items(regex, step, project_name)
		Dir.chdir("#{PROJECTS_PATH}/#{project_name}") do
			link_titles = step.scan(/"([^"]*)"/).flatten

			namespace = OpenStruct.new(link_titles: link_titles)
			menu_template = ERB.new(IO.read("#{Rails.root}/templates/menu.html.erb"))

			File.open("app/views/layouts/_menu.html.erb", "w+") do |file|
				file.write(menu_template.result(namespace.instance_eval { binding }))
			end

			# Commiting changes
			self.commit("Adding #{link_titles.join(' ')} menu items", project_name)
		end
	end

	def self.append_gem(gem_name, project_name)		
		return if Gem::Specification::find_all_by_name(gem_name).any?

		File.open("Gemfile", "a") { |file| file.puts "gem '#{gem_name}'" }

		# Installing the gem
		Bundler.with_clean_env do
			system("BUNDLE_GEMFILE=Gemfile bundle install")
		end
	end

	def self.commit(message, project_name)
		git = Git.open("./")
		git.add
		git.commit(message)
	end
end