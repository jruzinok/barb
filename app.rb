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
require_relative 'csv.rb'
require_relative 'directory.rb'
require_relative 'dialer_controller.rb'
require_relative 'dialer_guest.rb'
require_relative 'dialer_lead.rb'
require_relative 'dialer_payment_date.rb'
require_relative 'dialer_payment_method.rb'
require_relative 'event_attendee.rb'
require_relative 'model.rb'
require_relative 'payment_method.rb'
require_relative 'payment_method_tokens.rb'
require_relative 'payment_date.rb'
require_relative 'shared.rb'
require_relative 'transaction_attempt.rb'
require_relative 'payment_processor_log.rb'
require_relative 'current_student.rb'
require_relative 'current_student_controller.rb'
require_relative 'current_student_credit_card.rb'

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

	post '/update-payment-token/:database/:directory_id/:payment_method_id' do
		@process = "Update Payment Token"
		@processType = "Token"
		@database = params[:database]
		@directory_id = params[:directory_id]
		@payment_method_id = params[:payment_method_id]

		# Grab the credit card values from the POST object.
		@cardnumber = params[:CreditCard]
		@carddate = params[:MMYY]
		@cardcvv = params[:CVV]

		update_payment_token

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
		@payment_date_id = params[:payment_date_id]

		process_transaction_attempt

		# Return the response back to FileMaker.
		status @status
		body @body
	end

	# This was designed to be called from the BookingDialer php web app.
	get '/create-dialer-lead-customer-token/:lead_id' do
		@process = "Create Dialer Lead Customer Token"
		@lead_id = params[:lead_id]
		@processType = "Token"
		@database = "DL"
		@recordtype = "DialerLead"
		create_dialer_lead_customer_token

		# Return the response back to the Dialer.
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
	# This new version ONLY creates tokens.
	post '/create-dialer-lead-payment-method-v2/:lead_id' do
		@process = "Create Dialer Lead PaymentMethod"
		@processType = "Token"
		@database = "DL"
		@recordtype = "DialerLead"
		process_create_dialer_payment_method_request_v2

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
	# This new version ONLY creates tokens.
	post '/create-dialer-guest-payment-method-v2/:lead_id/:guest_id' do
		@process = "Create Dialer Guest PaymentMethod"
		@processType = "Token"
		@database = "DL"
		@recordtype = "DialerGuest"
		process_create_dialer_payment_method_request_v2

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

	# This was designed to create customer tokens for a batch of Current Student records.
	get '/batch-tokenize-current-students/:batch' do
		@process = "Batch Tokeninzation of Current Students"
		@processType = "Token"
		@database = "CS"
		@batch = params[:batch]
		batch_tokenize_current_students

		# Return the response back to FileMaker.
		status 200
		body "Processed"
	end

	# This was designed to create payment tokens for a batch of Current Student's Credit Card records.
	get '/batch-tokenize-current-student-credit-cards/:batch' do
		@process = "Batch Tokeninzation of Current Students' Credit Cards"
		@processType = "Token"
		@database = "CS"
		@batch = params[:batch]
		batch_tokenize_current_student_credit_cards

		# Return the response back to FileMaker.
		status 200
		body "Processed"
	end

	# This was designed to create customer tokens for a batch of CVS of Customer Data.
	get '/batch-tokenize-csv-customer-files/:batch' do
		@process = "Batch Tokeninzation of CSV Customer Data"
		@processType = "Token"
		@batch = params[:batch]
		batch_tokenize_csv_customer_data

		# Return the response back to FileMaker.
		status 200
		body "Processed"
	end

	# This was designed to create payments tokens for a batch of CVS of Credit Card Data.
	get '/batch-tokenize-csv-credit-card-files/:batch' do
		@process = "Batch Tokeninzation of CSV Credit Card Data"
		@processType = "Token"
		@batch = params[:batch]
		batch_tokenize_csv_credit_card_data

		# Return the response back to FileMaker.
		status 200
		body "Processed"
	end

	# This was designed to create payments tokens for a batch of CVS of Credit Card Data.
	get '/batch-validate-tokens/:database/:batch' do
		@process = "Batch Token Validation"
		@processType = "Token"
		@database = params[:database]
		@batch = params[:batch]
		validate_multiple_tokens

		# Return the response back to FileMaker.
		status 200
		body "Processed"
	end

end
