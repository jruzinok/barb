include AuthorizeNet::API

def transaction
	if transaction_ready
		transaction = Transaction.new(@api_login_id, @api_transaction_key, @gateway)
	else
		@result = "ERROR"
		@response_kind = "TransactionNotAttempted"
		@status_code = 99
		@response_error = "Merchant variables are missing."
	end
end

def create_customer_token
	request = CreateCustomerProfileRequest.new
	request.profile = CustomerProfileType.new(@customer,@name_full,nil,nil,nil) #(merchantCustomerId,description,email,paymentProfiles,shipToList)

	@response = transaction.create_customer_profile(request)

	# The transaction has a response.
	if transaction_ok
		@has_customer_token = true
		@customer_token = @response.customerProfileId
		@status_code = 200
		@status_message = "[OK] CustomerTokenCreated"
		@return_json_package = JSON.generate ["response_kind"=>@response_kind,"status_code"=>@status_code,"status_message"=>@status_message,"customer_token"=>@customer_token][0]
	else
		@status_code = 199 # Most likely caused by a '@customer' id issue.
		@status_message = "[ERROR] CustomerTokenNotCreated"
		@return_json_package = JSON.generate ["response_kind"=>@response_kind,"status_code"=>@status_code,"status_message"=>@status_message,"response_code"=>@response_code,"response_error"=>@response_error][0]
	end
	log_result_to_console
end

def create_payment_token
	request = CreateCustomerPaymentProfileRequest.new
	creditcard = CreditCardType.new(@card_number,@card_mmyy,@card_cvv)
	payment = PaymentType.new(creditcard)

	# Build an address object
	billTo = CustomerAddressType.new
	billTo.firstName = @card_name_first
	billTo.lastName = @card_name_last
	billTo.address = @address
	billTo.city = @city
	billTo.state = @state
	billTo.zip = @zip
	billTo.phoneNumber = @phone

	# Use the previously defined payment and billTo objects to
	# build a payment profile to send with the request
	paymentProfile = CustomerPaymentProfileType.new
	paymentProfile.payment = payment
	paymentProfile.billTo = billTo
	paymentProfile.defaultPaymentProfile = true

	# Build the request object

	request.paymentProfile = paymentProfile
	request.customerProfileId = @customer_token

	@response = transaction.create_customer_payment_profile(request)

	# The transaction has a response.
	if transaction_ok
		@payment_token = @response.customerPaymentProfileId
		@has_payment_token = true
		@status_code = 200
		@status_message = "[OK] PaymentTokenCreated"
		@maskedCardNumber = @card_number.split(//).last(4).join
		@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message,"payment_token"=>@payment_token,"card_number"=>@maskedCardNumber][0]
	else
		@status_code = 196
		@status_message = "[ERROR] PaymentTokenNotCreated"
		@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message,"response_code"=>@response_code,"response_error"=>@response_error][0]
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
			@result = "ERROR"

			@response_kind = "TokenError"
		end

			# A transactional FAILURE occurred. [NIL]
		else
			@valid_tokens = false
			@result = "ERROR"

			@response_kind = "TransactionFailure"
			@response_error = "A transactional FAILURE occurred."
		end

	rescue Errno::ETIMEDOUT => e
		@result = "ERROR"

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
				@result = "OK"

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
				@result = "ERROR"

				@response_kind = "TransactionError"
				@response_code = @response.transactionResponse.errors.errors[0].errorCode
				@response_error = @response.transactionResponse.errors.errors[0].errorText
			end

		# A transactional FAILURE occurred. [NIL]
		else
			@result = "ERROR"

			@response_kind = "TransactionFailure"
			@response_error = "A transactional FAILURE occurred."
		end

	rescue Errno::ETIMEDOUT => e
		@result = "ERROR"

		@response_kind = "TransactionFailure"
		@response_error = "Authorize.net isn't available."
	end
end
