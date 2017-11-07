include AuthorizeNet::API

def transaction
	# # LOAD the Authorize.net api credentials.
	# credentials = YAML.load_file(File.dirname(__FILE__) + "/config/credentials.yml")

	# # CREATE the transaction.
	# transaction = Transaction.new(credentials['api_login_id'], credentials['api_transaction_key'], :gateway => :production)
	# # transaction = Transaction.new(credentials['api_login_id'], credentials['api_transaction_key'], {:gateway => :sandbox, :verify_ssl => true})

	transaction = Transaction.new(ENV['AUTHORIZE_API_ID'], ENV['AUTHORIZE_API_KEY'], :gateway => ENV['AUTHORIZE_API_ENDPOINT'].to_sym)
end

def validate_tokens
	request = ValidateCustomerPaymentProfileRequest.new

	#Edit this part to select a specific customer
	request.customerProfileId = @customer_token
	request.customerPaymentProfileId = @payment_token
	request.validationMode = ValidationModeEnum::TestMode

	# PASS the transaction request and CAPTURE the transaction response.
	response = transaction.validate_customer_payment_profile(request)

	# Ensure that a response was received before proceeding.
	begin
		if response.messages != nil

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

			# A transactional FAILURE occurred. [NIL]
		else
			@valid_tokens = false
			@resultCode = "ERROR"

			@responseKind = "TransactionFailure"
			@responseError = "A transactional FAILURE occurred."
		end

	rescue Errno::ETIMEDOUT => e
		@resultCode = "ERROR"

		@responseKind = "TransactionFailure"
		@responseError = "Authorize.net isn't available."
	end
end

# This method connects all of the payment processing methods together.
def process_payment
	request = CreateTransactionRequest.new
	request.transactionRequest = TransactionRequestType.new()
	request.transactionRequest.amount = @amount
	request.transactionRequest.transactionType = TransactionTypeEnum::AuthCaptureTransaction
	
	if @card_or_tokens == "tokens"
		request.transactionRequest.profile = CustomerProfilePaymentType.new
		request.transactionRequest.profile.customerProfileId = @customer_token
		request.transactionRequest.profile.paymentProfile = PaymentProfile.new(@payment_token)	
	elsif @card_or_tokens == "card"
		request.transactionRequest.payment = PaymentType.new
		request.transactionRequest.payment.creditCard = CreditCardType.new(@cardnumber, @carddate, @cardcvv)
	end

	# The @gl_code and @invoice were set dynamically in the set_gl_code method located in the shared.rb file.
	request.transactionRequest.order = OrderType.new()
	request.transactionRequest.order.invoiceNumber = @invoice
	request.transactionRequest.order.description = @gl_code
	
	# PASS the transaction request and CAPTURE the transaction response.
	response = transaction.create_transaction(request)

	begin
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
			@resultCode = "ERROR"

			@responseKind = "TransactionFailure"
			@responseError = "A transactional FAILURE occurred."
		end

	rescue Errno::ETIMEDOUT => e
		@resultCode = "ERROR"

		@responseKind = "TransactionFailure"
		@responseError = "Authorize.net isn't available."
	end
end
