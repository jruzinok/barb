include AuthorizeNet::API

def transaction
	if transaction_ready
		transaction = Transaction.new(@api_login_id, @api_transaction_key, gateway)
	else
		@result_code = "ERROR"

		@response_kind = "TransactionNotAttempted"
		@response_error = "Merchant variables are missing."
	end
end

def validate_tokens
	request = ValidateCustomerPaymentProfileRequest.new

	#Edit this part to select a specific customer
	request.customerProfileId = @customer_token
	request.customerPaymentProfileId = @payment_token
	request.validationMode = ValidationModeEnum::TestMode

	# PASS the transaction request and CAPTURE the transaction response.
	@response = transaction.validate_customer_payment_profile(request)

	# Ensure that a response was received before proceeding.
	begin
		if @response.messages != nil

		if transaction_ok
			@valid_tokens = true
		else
			@valid_tokens = false

			# Capture the complete response and set the ResultCode (logic variable) to Error.
			@result_code = "ERROR"

			@response_kind = "TokenError"
		end

			# A transactional FAILURE occurred. [NIL]
		else
			@valid_tokens = false
			@result_code = "ERROR"

			@response_kind = "TransactionFailure"
			@response_error = "A transactional FAILURE occurred."
		end

	rescue Errno::ETIMEDOUT => e
		@result_code = "ERROR"

		@response_kind = "TransactionFailure"
		@response_error = "Authorize.net isn't available."
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
		request.transactionRequest.payment.creditCard = CreditCardType.new(@card_number, @card_mmyy, @card_cvv)
	end

	# The @gl_code and @invoice were set dynamically in the set_gl_code method located in the shared.rb file.
	request.transactionRequest.order = OrderType.new()
	request.transactionRequest.order.invoiceNumber = @invoice
	request.transactionRequest.order.description = @gl_code
	
	# PASS the transaction request and CAPTURE the transaction response.
	@response = transaction.create_transaction(request)

	begin
		if @response.transactionResponse != nil

			# Capture the response variables for all transactions.
			@avs_code = response.transactionResponse.avsResultCode
			@cvv_code = response.transactionResponse.cvvResultCode

			# The transaction has a response.
			if transaction_ok
				@result_code = "OK"

				# CAPTURE the transaction details.
				@transaction_id = @response.transactionResponse.transId
				@transaction_response_code = @response.transactionResponse.responseCode

				if @transaction_response_code == "1"
					@response_kind = "Approved"
					@authorization_code = @response.transactionResponse.authCode
					@response_code = @response.messages.messages[0].code
					@response_message = @response.messages.messages[0].text

				elsif @transaction_response_code == "2"
					@response_kind = "Declined"
					@response_code = @response.transactionResponse.errors.errors[0].errorCode
					@response_error = @response.transactionResponse.errors.errors[0].errorText

				elsif @transaction_response_code == "3"
					@response_kind = "Error"
					@response_code = @response.transactionResponse.errors.errors[0].errorCode
					@response_error = @response.transactionResponse.errors.errors[0].errorText

				elsif @transaction_response_code == "4"
					@response_kind = "HeldforReview"
					@response_code = @response.transactionResponse.errors.errors[0].errorCode
					@response_error = @@response.transactionResponse.errors.errors[0].errorText
				end

			# A transactional ERROR occurred.
			elsif @response.messages.resultCode == MessageTypeEnum::Error
				@result_code = "ERROR"

				@response_kind = "TransactionError"
				@response_code = @response.transactionResponse.errors.errors[0].errorCode
				@response_error = @response.transactionResponse.errors.errors[0].errorText
			end

		# A transactional FAILURE occurred. [NIL]
		else
			@result_code = "ERROR"

			@response_kind = "TransactionFailure"
			@response_error = "A transactional FAILURE occurred."
		end

	rescue Errno::ETIMEDOUT => e
		@result_code = "ERROR"

		@response_kind = "TransactionFailure"
		@response_error = "Authorize.net isn't available."
	end
end
