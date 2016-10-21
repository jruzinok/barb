require 'bigdecimal'

# def show
# 	@record = PaymentDate.find params[:id]
# end

def find_by_batch
	if @database == "PTD"
		@payment_dates = PTDPaymentDate.find(:_kF_PaymentBatch => @batch)
	elsif @database == "BC"
		@payment_dates = BCPaymentDate.find(:_kF_PaymentBatch => @batch)
	end
end

def find_by_status_and_date
	if @database == "PTD"
		@payment_dates = PTDPaymentDate.find(:zzF_Status => @status, :Date => @date)
	elsif @database == "BC"
		@payment_dates = BCPaymentDate.find(:zzF_Status => @status, :Date => @date)
	end
end

def process
	find_by_batch

	# This outputs the batch id. It's used to display acts as the header or beginning of the process
	puts "\n\n\n\n\n"
	puts "\n----------------------------------------"
	puts "\n[DATABASE] #{@database}"
	puts "\n[BATCH] #{@batch})"
	puts "\n[TIMESTAMP] #{Time.now.utc.iso8601}"
	puts "\n----------------------------------------"

	@payment_dates.each do |pd|
		@payment_date = pd
		# These "steps" are for clarity sake.
		# Later, these objects could be saved somewhere to log the steps of each batch when it's run.
		@step1 = load_payment_date
		@step2 = process_or_skip
		@step3 = report
		@step4 = update_payment_date
		@step5 = clear
	end

	# This final step calls the Payment Processor Tool script in the Payment Processor application file.
	# @step6 = BCPaymentDate.find({:_kF_PaymentBatch => @batch}, :post_script => ["PaymentProcessorCallBack", "#{@batch}\nInitiate from Ruby"])
end

def load_payment_date
	@serial = @payment_date["_Serial"].to_i
	@namefirst = @payment_date["T54_Link | DIRECTORY ~ contestant::Name_First"]
	@namelast = @payment_date["T54_Link | DIRECTORY ~ contestant::Name_Last"]

	# Address values.
	@address = @payment_date["T54_PaymentMethod | CONTACTINFO::Add_Address1"]
	@city = @payment_date["T54_PaymentMethod | CONTACTINFO::Add_City"]
	@state = @payment_date["T54_PaymentMethod | CONTACTINFO::Add_State"]
	@zip = @payment_date["T54_PaymentMethod | CONTACTINFO::Add_Zip"]

	# TBD: CAPTURE the customer's profile id and payment id.
	@customer_token = @payment_date["T54_DIRECTORY::Token_Profile_ID"]
	@payment_token = @payment_date["T54_PAYMENTMETHOD::Token_Payment_ID"]

	# Credit Card values.
	@cardnumber = @payment_date["T54_PAYMENTMETHOD::CreditCard_Number"]
	@carddate = @payment_date["T54_PAYMENTMETHOD::MMYY"]
	@cardcvv = @payment_date["T54_PAYMENTMETHOD::CVV"]

	# Transaction details.
	@amount = @payment_date["Amount"].to_f
	@bc = @payment_date["T54_LINK::zzC_BC_Location_ABBR"]
end

# This determines whether or not to process this payment or not.
def process_or_skip

	# Check if this payment is by ids or card.
	ids_or_card

	if @ids_or_card == "ids" || @ids_or_card == "card"
		process_payment
	end
end

# This determines if this transaction should be processed using Authorize IDs or a CC.
def ids_or_card

	# If this record has (Authorize.net) IDs, validate them.
	if @customer_token && @payment_token

		# Validate the IDs.
		validate_ids

		if @valid_authorize_ids == true
			@ids_or_card = "ids"
		else
			@ids_or_card = "Error"
		end

	# If this record has credit card values, use them.
	else
		@ids_or_card = "card"
	end
end

def validate_ids
	request = ValidateCustomerPaymentProfileRequest.new

	#Edit this part to select a specific customer
	request.customerProfileId = @customer_token
	request.customerPaymentProfileId = @payment_token
	request.validationMode = ValidationModeEnum::TestMode

	# PASS the transaction request and CAPTURE the transaction response.
	response = transaction.validate_customer_payment_profile(request)

	if response.messages.resultCode == MessageTypeEnum::Ok
		@valid_authorize_ids = true
	else
		@valid_authorize_ids = false

		# Capture the complete response and set the ResultCode (logic variable) to Error.
		@theResponse = response
		@resultCode = "ERROR"

		@responseKind = "TokenError"
		@responseCode = response.messages.messages[0].code
		@responseError = response.messages.messages[0].text
	end
end

def report

	# This determines what to output, either the authorization or error data.
	responseOutput =
	if @responseKind == "Approved"
		"Authorization: #{@authorizationCode}"
	else
		"Error: #{@responseError}"
	end

	# This determines what to output, either the card number or customer profile and payment ids.
	paymentMethod =
	if @ids_or_card == "card"
		"Card: #{@cardnumber}"
	else
		"Profile: #{@customer_token} Payment: #{@payment_token}"
	end

	puts "\nRESPONSE: [#{@responseKind}]"
	puts "MESSAGE: #{responseOutput}"
	puts "CODE: #{@responseCode}"
	puts "RECORD: #{@serial}"
	puts "METHOD: #{paymentMethod}"
	puts "\n----------------------------------------"
end

def update_payment_date
		# SAVE the response values for all transactions.

	# Record the transaction results for each processed payment.
	if @resultCode == "OK"
		@payment_date[:zzPP_Transaction] = @transactionID

		@payment_date[:zzPP_Response] = @theResponse
		@payment_date[:zzPP_Response_AVS_Code] = @avsCode
		@payment_date[:zzPP_Response_CVV_Code] = @cvvCode

		@payment_date[:zzPP_Response_Code] = @responseCode

		if @responseKind == "Approved"
			@payment_date[:zzF_Status] = "Approved"
			@payment_date[:zzPP_Authorization_Code] = @authorizationCode
			@payment_date[:zzPP_Response_Message] = @responseMessage

		elsif @responseKind == "Declined"
			@payment_date[:zzF_Status] = "Declined"
			@payment_date[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "Error"
			@payment_date[:zzF_Status] = "Error"
			@payment_date[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "HeldforReview"
			@payment_date[:zzF_Status] = "HeldForReview"
			@payment_date[:zzPP_Response_Error] = @responseError
		end

	# These payments were NOT processes.
	else
		if @responseKind == "TransactionError"
			@payment_date[:zzF_Status] = "Error"
			@payment_date[:zzPP_Transaction] = @transactionID

			@payment_date[:zzPP_Response] = @theResponse
			@payment_date[:zzPP_Response_Code] = @responseCode
			@payment_date[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "TokenError"
			@payment_date[:zzPP_Response] = @theResponse
			@payment_date[:zzPP_Response_Code] = @responseCode
			@payment_date[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "TransactionFailure"
			@payment_date[:zzPP_Response_Error] = @responseError
		end
	end

	@payment_date.save
end

def clear
	@theResponse = ""
	@resultCode = ""
	@transactionID = ""
	@avsCode = ""
	@cvvCode = ""
	@responseCode = ""
	@responseKind = ""
	@authorizationCode = ""
	@responseMessage = ""
	@responseError = ""
end