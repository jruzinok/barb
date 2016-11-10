require 'rubygems'
require 'yaml'
require 'rfm'
require 'authorizenet'
# require 'rack-flash'
require 'rack/cors'
require 'sinatra'
require 'openssl'

set :environment, :production

use Rack::Cors do
	allow do
		origins '*'
		resource '*', headers: :any, methods: :any
	end
end

# This loads the Ruby 2 FileMaker server configuration settings.
config = YAML.load_file(File.dirname(__FILE__) + "/config/rfm.yml")

require_relative 'authorize.rb'
require_relative 'directory.rb'
require_relative 'dialer_controller.rb'
require_relative 'dialer_guest.rb'
require_relative 'dialer_lead.rb'
require_relative 'dialer_payment_date.rb'
require_relative 'dialer_payment_method.rb'
require_relative 'model.rb'
require_relative 'payment_method.rb'
require_relative 'payment_date.rb'
require_relative 'shared.rb'
require_relative 'transaction_attempt.rb'
require_relative 'payment_processor_log.rb'

class PaymentProcessor < Sinatra::Application


	# This route is for the php WebDialer to check that it can connect to the sinatra PaymentProcessor.
	get '/ping' do
		status 200
		body "1"
	end

	get '/process/:database/:batch' do
		@process = "Batch Process"
		@processType = "Payment"
		@database = params[:database]
		@batch = params[:batch]
		process_payment_dates

		# Return the response back to FileMaker.
		status 200
		body "Processed"
	end

	get '/create-customer-token/:database/:directory_id' do
		@process = "Create Customer Token"
		@processType = "Token"
		@database = params[:database]
		@directory_id = params[:directory_id]
		create_customer_token
	end

	post '/create-payment-token/:database/:directory_id/:payment_method_id' do
		@process = "Create Payment Token"
		@processType = "Token"
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

	post '/process-transaction-attempt/:database/:directory_id/:statement_id/:payment_method_id' do
		@process = "Transaction Attempt"
		@processType = "Payment"
		@database = params[:database]
		@directory_id = params[:directory_id]
		@statement_id = params[:statement_id]
		@payment_method_id = params[:payment_method_id]
		@amount = params[:Amount]
		@date = params[:Date]

		process_transaction_attempt

		# Return the response back to FileMaker.
		status @status
		body @body
	end

	# This was designed to be called from the BookingDialer php web app.
	post '/create-dialer-lead-payment-method/:lead_id' do
		@process = "Create Dialer Lead PaymentMethod"
		@processType = "Token"
		@database = "DL"
		@recordtype = "DialerLead"
		process_create_dialer_payment_method_request

		# Return the response back to the Dialer.
		status @status
		body @body
	end

	# This was designed to be called from the BookingDialer php web app.
	post '/create-dialer-lead-payment/:lead_id/:payment_method_id' do
		@process = "Create Dialer Lead PaymentDate"
		@processType = "Payment"
		@database = "DL"
		@recordtype = "DialerLead"
		process_create_dialer_payment_date_request

		# Return the response back to the Dialer.
		status @status
		body @body
	end

	# This was designed to be called from the BookingDialer php web app.
	post '/create-dialer-guest-payment-method/:lead_id/:guest_id' do
		@process = "Create Dialer Guest PaymentMethod"
		@processType = "Token"
		@database = "DL"
		@recordtype = "DialerGuest"
		process_create_dialer_payment_method_request

		# Return the response back to the Dialer.
		status @status
		body @body
	end

	# This was designed to be called from the BookingDialer php web app.
	post '/create-dialer-guest-payment/:lead_id/:guest_id/:payment_method_id' do
		@process = "Create Dialer Guest PaymentDate"
		@processType = "Payment"
		@database = "DL"
		@recordtype = "DialerGuest"
		process_create_dialer_payment_date_request

		# Return the response back to the Dialer.
		status @status
		body @body
	end
end
