require 'bigdecimal'

# def show
# 	@record = PaymentDate.find params[:id]
# end

def find_by_batch
	if @database == "PTD"
		@paymentdates = PTDPaymentDate.find(:_kF_PaymentBatch => @batch)
	elsif @database == "BC"
		@paymentdates = BCPaymentDate.find(:_kF_PaymentBatch => @batch)
	end
end

def find_by_status_and_date
	if @database == "PTD"
		@paymentdates = PTDPaymentDate.find(:zzF_Status => @status, :Date => @date)
	elsif @database == "BC"
		@paymentdates = BCPaymentDate.find(:zzF_Status => @status, :Date => @date)
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

	@paymentdates.each do |pd|
		@paymentdate = pd
		# These "steps" are for clarity sake.
		# Later, these objects could be saved somewhere to log the steps of each batch when it's run.
		@step1 = load
		@step2 = process_or_skip
		@step3 = report
		@step4 = update
		@step5 = clear
	end

	# This final step calls the Payment Processor Tool script in the Payment Processor application file.
	# @step6 = BCPaymentDate.find({:_kF_PaymentBatch => @batch}, :post_script => ["PaymentProcessorCallBack", "#{@batch}\nInitiate from Ruby"])
end

def load
	@serial = @paymentdate["_Serial"].to_i
	@namefirst = @paymentdate["T54_Link | DIRECTORY ~ contestant::Name_First"]
	@namelast = @paymentdate["T54_Link | DIRECTORY ~ contestant::Name_Last"]

	# Address values.
	@address = @paymentdate["T54_PaymentMethod | CONTACTINFO::Add_Address1"]
	@city = @paymentdate["T54_PaymentMethod | CONTACTINFO::Add_City"]
	@state = @paymentdate["T54_PaymentMethod | CONTACTINFO::Add_State"]
	@zip = @paymentdate["T54_PaymentMethod | CONTACTINFO::Add_Zip"]

	# TBD: CAPTURE the customer's profile id and payment id.
	@customer_token = @paymentdate["T54_DIRECTORY::Token_Profile_ID"]
	@payment_token = @paymentdate["T54_PAYMENTMETHOD::Token_Payment_ID"]

	# Credit Card values.
	@cardnumber = @paymentdate["T54_PAYMENTMETHOD::CreditCard_Number"]
	@carddate = @paymentdate["T54_PAYMENTMETHOD::MMYY"]
	@cardcvv = @paymentdate["T54_PAYMENTMETHOD::CVV"]

	# Transaction details.
	@amount = @paymentdate["Amount"].to_f
	@bc = @paymentdate["T54_LINK::zzC_BC_Location_ABBR"]
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

def update
		# SAVE the response values for all transactions.

	# Record the transaction results for each processed payment.
	if @resultCode == "OK"
		@paymentdate[:zzPP_Transaction] = @transactionID

		@paymentdate[:zzPP_Response] = @theResponse
		@paymentdate[:zzPP_Response_AVS_Code] = @avsCode
		@paymentdate[:zzPP_Response_CVV_Code] = @cvvCode

		@paymentdate[:zzPP_Response_Code] = @responseCode

		if @responseKind == "Approved"
			@paymentdate[:zzF_Status] = "Approved"
			@paymentdate[:zzPP_Authorization_Code] = @authorizationCode
			@paymentdate[:zzPP_Response_Message] = @responseMessage

		elsif @responseKind == "Declined"
			@paymentdate[:zzF_Status] = "Declined"
			@paymentdate[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "Error"
			@paymentdate[:zzF_Status] = "Error"
			@paymentdate[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "HeldforReview"
			@paymentdate[:zzF_Status] = "HeldForReview"
			@paymentdate[:zzPP_Response_Error] = @responseError
		end

	# These payments were NOT processes.
	else
		if @responseKind == "TransactionError"
			@paymentdate[:zzF_Status] = "Error"
			@paymentdate[:zzPP_Transaction] = @transactionID

			@paymentdate[:zzPP_Response] = @theResponse
			@paymentdate[:zzPP_Response_Code] = @responseCode
			@paymentdate[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "TokenError"
			@paymentdate[:zzPP_Response] = @theResponse
			@paymentdate[:zzPP_Response_Code] = @responseCode
			@paymentdate[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "TransactionFailure"
			@paymentdate[:zzPP_Response_Error] = @responseError
		end
	end

	@paymentdate.save
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