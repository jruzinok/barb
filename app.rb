require 'rubygems'
require 'yaml'
require 'rfm'
require 'authorizenet'
# require 'rack-flash'
require 'sinatra'

# This loads the Ruby 2 FileMaker server configuration settings.
config = YAML.load_file(File.dirname(__FILE__) + "/config/rfm.yml")

require_relative 'models/paymentdate.rb'
require_relative 'controllers/paymentdate_controller.rb'
require_relative 'controllers/paymentdate_process.rb'

class CreditCard < Sinatra::Application

	get '/process/:database/:batch' do
		@database = params[:database]
		@batch = params[:batch]
		process
	end

	# FUTURE DEVELOPMENT
	# get '/:auth/:batch' do
		# @auth = params[:auth]
		# @batch = params[:batch]
		# if @auth == env['APP_PASSWORD']
		# 	process (@batch)
		# else
		# 	redirect 'www.google.com'
		# end
	# end

end