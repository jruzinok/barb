require 'rubygems'
require 'yaml'
require 'rfm'
require 'authorizenet'
# require 'rack-flash'
require 'sinatra'
require 'openssl'

set :environment, :production

# This loads the Ruby 2 FileMaker server configuration settings.
config = YAML.load_file(File.dirname(__FILE__) + "/config/rfm.yml")

require_relative 'model.rb'
require_relative 'paymentdate_controller.rb'
require_relative 'paymentdate_process.rb'
require_relative 'directory.rb'
require_relative 'paymentmethod.rb'
require_relative 'dialerlead.rb'
require_relative 'dialerpayment.rb'
require_relative 'shared.rb'

class CreditCard < Sinatra::Application

	get '/process/:database/:batch' do
		@database = params[:database]
		@batch = params[:batch]
		process
	end
end

class Profiles < Sinatra::Application

	get '/create-customer-token/:database/:directory_id' do
		@database = params[:database]
		@directory_id = params[:directory_id]
		create_customer_token
	end

	post '/create-payment-token/:database/:directory_id/:payment_method_id' do
		@database = params[:database]
		@directory_id = params[:directory_id]
		@payment_method_id = params[:payment_method_id]

		# Grab the credit card values from the POST object.
		@cardnumber = params[:CreditCard]
		@carddate = params[:MMYY]
		@cardcvv = params[:CVV]

		create_payment_token

		# Return the response back to FileMaker.
		status @status
		body @body
	end

	# This was designed to be called from the BookingDialer php web app.
	post '/create-dialer-lead-payment/:lead_id' do
		@database = "DL"
		@recordtype = "DialerLead"
		process_create_dialier_payment_request

		# Return the response back to the Dialer.
		status @status
		body @body
	end

	# This was designed to be called from the BookingDialer php web app.
	post '/create-dialer-guest-payment/:lead_id/:guest_id' do
		@database = "DL"
		@recordtype = "DialerGuest"
		process_create_dialier_payment_request

		# Return the response back to the Dialer.
		status @status
		body @body
	end
end
