include AuthorizeNet::API

def transaction
	# LOAD the Authorize.net api credentials.
	credentials = YAML.load_file(File.dirname(__FILE__) + "/config/credentials.yml")

	# CREATE the transaction.
	transaction = Transaction.new(credentials['api_login_id'], credentials['api_transaction_key'], :gateway => :sandbox)
end

def validate_tokens
	request = ValidateCustomerPaymentProfileRequest.new

	#Edit this part to select a specific customer
	request.customerProfileId = @customer_token
	request.customerPaymentProfileId = @payment_token
	request.validationMode = ValidationModeEnum::TestMode

	# PASS the transaction request and CAPTURE the transaction response.
	response = transaction.validate_customer_payment_profile(request)

	if response.messages.resultCode == MessageTypeEnum::Ok
		@valid_tokens = true
	else
		@valid_tokens = false

		# Capture the complete response and set the ResultCode (logic variable) to Error.
		@theResponse = response
		@resultCode = "ERROR"

		@responseKind = "TokenError"
		@responseCode = response.messages.messages[0].code
		@responseError = response.messages.messages[0].text
	end
end

# This method connects all of the payment processing methods together.
def process_payment
	request = CreateTransactionRequest.new
	request.transactionRequest = TransactionRequestType.new()
	request.transactionRequest.amount = @amount
	request.transactionRequest.transactionType = TransactionTypeEnum::AuthCaptureTransaction
	
	if @card_or_token == "ids"
		request.transactionRequest.profile = CustomerProfilePaymentType.new
		request.transactionRequest.profile.customerProfileId = @customer_token
		request.transactionRequest.profile.paymentProfile = PaymentProfile.new(@payment_token)	
	elsif @card_or_token == "card"
		request.transactionRequest.payment = PaymentType.new
		request.transactionRequest.payment.creditCard = CreditCardType.new(@cardnumber, @carddate, @cardcvv)
	end

	# HARDCODED GL CODES MUST be updated to set the year value dynamically.
	if @database == "PTD"
		request.transactionRequest.order = OrderType.new()
		request.transactionRequest.order.invoiceNumber = @ptd_invoice_number
		request.transactionRequest.order.description = @ptd_gl_code
	elsif @database == "BC"
		request.transactionRequest.order = OrderType.new()
		request.transactionRequest.order.invoiceNumber = @bc_invoice_number
		request.transactionRequest.order.description = @bc_gl_code
	elsif @database == "DL" #DialerLeads
		request.transactionRequest.order = OrderType.new()
		request.transactionRequest.order.invoiceNumber = @ptd_invoice_number
		request.transactionRequest.order.description = @ptd_gl_code
	end
	
	# PASS the transaction request and CAPTURE the transaction response.
	response = transaction.create_transaction(request)

	if response.transactionResponse != nil

		# Capture the response variables for all transactions.
		@theResponse = response
		@avsCode = response.transactionResponse.avsResultCode
		@cvvCode = response.transactionResponse.cvvResultCode

		# The transaction has a response.
		if response.messages.resultCode == MessageTypeEnum::Ok
			@resultCode = "OK"

			# CAPTURE the transaction details.
			@transactionID = response.transactionResponse.transId
			@transactionResponseCode = response.transactionResponse.responseCode

			if @transactionResponseCode == "1"
				@responseKind = "Approved"
				@authorizationCode = response.transactionResponse.authCode
				@responseCode = response.messages.messages[0].code
				@responseMessage = response.messages.messages[0].text

			elsif @transactionResponseCode == "2"
				@responseKind = "Declined"
				@responseCode = response.transactionResponse.errors.errors[0].errorCode
				@responseError = response.transactionResponse.errors.errors[0].errorText

			elsif @transactionResponseCode == "3"
				@responseKind = "Error"
				@responseCode = response.transactionResponse.errors.errors[0].errorCode
				@responseError = response.transactionResponse.errors.errors[0].errorText

			elsif @transactionResponseCode == "4"
				@responseKind = "HeldforReview"
				@responseCode = response.transactionResponse.errors.errors[0].errorCode
				@responseError = response.transactionResponse.errors.errors[0].errorText
			end

		# A transactional ERROR occurred.
		elsif response.messages.resultCode == MessageTypeEnum::Error
			@resultCode = "ERROR"

			@responseKind = "TransactionError"
			@responseCode = response.transactionResponse.errors.errors[0].errorCode
			@responseError = response.transactionResponse.errors.errors[0].errorText
		end

	# A transactional FAILURE occurred. [NIL]
	else
		@responseKind = "TransactionFailure"
		@responseError = "A transactional FAILURE occurred."
	end
end
