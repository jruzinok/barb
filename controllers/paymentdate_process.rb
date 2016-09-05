include AuthorizeNet::API

# This method string all the following methods together.
def process_payment
	@process1 = create_request

	if @has_authorize_ids == true
		@process2 = charge_customer_profile
	else
		@process2 = charge_credit_card
	end

	@process3 = set_gl_codes
	@process4 = initiate_transaction
	@process5 = capture_response
end

def create_request
	request = CreateTransactionRequest.new
	request.transactionRequest = TransactionRequestType.new()
	request.transactionRequest.transactionType = TransactionTypeEnum::AuthCaptureTransaction
	request.transactionRequest.amount = @amount
end

def charge_credit_card
	request.transactionRequest.payment = PaymentType.new
	request.transactionRequest.payment.creditCard = CreditCardType.new(@cardnumber, @carddate, @cardcvv)
end

def charge_customer_profile(customerProfileId = '36731856', customerPaymentProfileId = '33211899')
	request.transactionRequest.profile = CustomerProfilePaymentType.new
	request.transactionRequest.profile.customerProfileId = customerProfileId
	request.transactionRequest.profile.paymentProfile = PaymentProfile.new(customerPaymentProfileId)
end

# HARDCODED GL CODES MUST be updated to set the year value dynamically.
def set_gl_codes
	if @database == "PTD"
		request.transactionRequest.order = OrderType.new()
		request.transactionRequest.order.invoiceNumber = "PTD16"
		request.transactionRequest.order.description = "423"	
	elsif @database == "BC"
		# HARDCODED GL CODES for BCs MUST be updated to be dynamic.
		request.transactionRequest.order = OrderType.new()
		request.transactionRequest.order.invoiceNumber = "BCOMP#{@bc}16"
		request.transactionRequest.order.description = "422"	
	end

end

def initiate_transaction
	config = YAML.load_file(File.dirname(__FILE__) + "/../config/credentials.yml")
	transaction = Transaction.new(config['api_login_id'], config['api_transaction_key'], :gateway => :production)
end

def capture_response
	response = initiate_transaction.create_transaction(request)

	if response.transactionResponse != nil

		# Capture the response variables for all transactions.
		@response = response
		# @avsCode = response.transactionResponse.avsResultCode
		# @cvvCode = response.transactionResponse.cvvResultCode

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
