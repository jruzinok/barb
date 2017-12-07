include AuthorizeNet::API

def transaction
	transaction = Transaction.new(@api_login_id, @api_transaction_key, @gateway)
end

def create_customer_token
	if transaction_ready
		request = CreateCustomerProfileRequest.new
		request.profile = CustomerProfileType.new(@customer,@name_full,nil,nil,nil) #(merchantCustomerId,description,email,paymentProfiles,shipToList)

		@authorize_response = transaction.create_customer_profile(request)

		# The transaction has a response.
		if transaction_ok
			@has_customer_token = true
			@customer_token = @authorize_response.customerProfileId
			@status_code = 200
			@status_message = "[OK] CustomerTokenCreated"
			@return_json_package = JSON.generate ["response_kind"=>@authorize_response_kind,"status_code"=>@status_code,"status_message"=>@status_message,"customer_token"=>@customer_token][0]
		else
			@status_code = 199 # Most likely caused by a '@customer' id issue.
			@status_message = "[ERROR] CustomerTokenNotCreated"
			@return_json_package = JSON.generate ["response_kind"=>@authorize_response_kind,"status_code"=>@status_code,"status_message"=>@status_message,"response_code"=>@authorize_response_code,"response_error"=>@authorize_response_error][0]
		end
		log_result_to_console
	end
end

def create_payment_token
	if transaction_ready
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

		@authorize_response = transaction.create_customer_payment_profile(request)

		# The transaction has a response.
		if transaction_ok
			@payment_token = @authorize_response.customerPaymentProfileId
			@has_payment_token = true
			@status_code = 200
			@status_message = "[OK] PaymentTokenCreated"
			@maskedCardNumber = @card_number.split(//).last(4).join
			@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message,"payment_token"=>@payment_token,"card_number"=>@maskedCardNumber][0]
			log_result_to_console
		else
			@status_code = 196
			@status_message = "[ERROR] PaymentTokenNotCreated"
			@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message,"response_code"=>@authorize_response_code,"response_error"=>@authorize_response_error][0]
			log_result_to_console
		end
	end
end

def update_payment_token
	if transaction_ready
		request = UpdateCustomerPaymentProfileRequest.new

		# Set the @card_mmyy = 'XXXX' and @card_cvv = nil if the user didn't enter any values.
		mask_card_date
		nil_card_cvv

		# The credit card number should not be updated per Ashley's decision. Hence the use of the @masked_card_number variable.
		creditcard = CreditCardType.new(@masked_card_number,@card_mmyy,@card_cvv)
		payment = PaymentType.new(creditcard)
		profile = CustomerPaymentProfileExType.new(nil,nil,payment,nil,nil)
		if @update_card_address == true
			profile.billTo = CustomerAddressType.new
			profile.billTo.firstName = @name_first
			profile.billTo.lastName = @name_last
			profile.billTo.address = @address
			profile.billTo.city = @city
			profile.billTo.state = @state
			profile.billTo.zip = @zip
		end
		request.paymentProfile = profile
		request.customerProfileId = @customer_token
		profile.customerPaymentProfileId = @payment_token

		# PASS the transaction request and CAPTURE the transaction response.
		@authorize_response = transaction.update_customer_payment_profile(request)

		if transaction_ok
			@payment_token_updated = true
			@status_code = 200
			@status_message = "[OK] PaymentTokenUpdated"
			log_result_to_console
		else
			@payment_token_updated = false
			@status_code = 210
			@status_message = "[ERROR] PaymentTokenNotUpdated"
			log_result_to_console
		end
	end
end

def delete_payment_token
	if transaction_ready
		request = DeleteCustomerPaymentProfileRequest.new
		request.customerProfileId = @customer_token
		request.customerPaymentProfileId = @payment_token

		@authorize_response = transaction.delete_customer_payment_profile(request)

		# The transaction has a response.
		if transaction_ok
			@status_code = 200
			@status_message = "[OK] PaymentTokenDeleted"
			log_result_to_console
		else
			@status_code = 194
			@status_message = "[ERROR] PaymentTokenNotDeleted"
			log_result_to_console
		end
	end
end

def validate_customer_token
	if transaction_ready
		request = GetCustomerProfileRequest.new

		if @check_by_merchant_id == true
			request.merchantCustomerId = @customer
		elsif @check_by_customer_token == true
			request.customerProfileId = @customer_token
		end

		@authorize_response = transaction.get_customer_profile(request)

		# Ensure that a response was received before proceeding.
		begin
			if @authorize_response.messages != nil

				if transaction_ok
					# This is the expected result when a webapp requests to create a PT.
					@has_customer_token = true
					@status_code = 200
					@status_message = "[OK] CustomerTokenExists"
					log_result_to_console
				else
					# This is the expected result when a webapp requests to create a CT.
					@has_customer_token = false
					@status_code = 194
					@status_message = "[ERROR] CustomerTokenDoesNotExist"
					log_result_to_console
				end

				# A transactional FAILURE occurred. [NIL]
			else
				@result = "ERROR"

				@authorize_response_kind = "TransactionFailure"
				@status_code = 198
				@status_message = "[ERROR] A transactional FAILURE occurred."
				@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message][0]
			end

		rescue Errno::ETIMEDOUT => e
			@result = "ERROR"

			@authorize_response_kind = "TransactionFailure"
			@status_code = 197
			@status_message = "[ERROR] Authorize.net isn't available."
			@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message][0]
		end
	end
end

def retrieve_payment_token
	if transaction_ready
		request = GetCustomerPaymentProfileRequest.new
		request.customerProfileId = @customer_token
		request.customerPaymentProfileId = @payment_token

		@authorize_response = transaction.get_customer_payment_profile(request)

		if transaction_ok
			@payment_token_retrieved = true
			@masked_card_number = @authorize_response.paymentProfile.payment.creditCard.cardNumber
			log_result_to_console
		else
			@payment_token_retrieved = false
			@status_code = 240
			@status_message = "[ERROR] PaymentTokenCouldNotBeRetrieved"
			log_result_to_console
		end
	end
end

def validate_tokens
	if transaction_ready
		request = ValidateCustomerPaymentProfileRequest.new

		#Edit this part to select a specific customer
		request.customerProfileId = @customer_token
		request.customerPaymentProfileId = @payment_token
		request.validationMode = ValidationModeEnum::TestMode

		# PASS the transaction request and CAPTURE the transaction response.
		@authorize_response = transaction.validate_customer_payment_profile(request)

		# Ensure that a response was received before proceeding.
		begin
			if @authorize_response.messages != nil

			if transaction_ok
				@valid_tokens = true
				log_result_to_console
			else
				@valid_tokens = false

				# Capture the complete response and set the ResultCode (logic variable) to Error.
				@result = "ERROR"

				@authorize_response_kind = "TokenError"
				log_result_to_console
			end

				# A transactional FAILURE occurred. [NIL]
			else
				@valid_tokens = false
				@result = "ERROR"

				@authorize_response_kind = "TransactionFailure"
				@authorize_response_error = "A transactional FAILURE occurred."
			end

		rescue Errno::ETIMEDOUT => e
			@result = "ERROR"

			@authorize_response_kind = "TransactionFailure"
			@authorize_response_error = "Authorize.net isn't available."
		end
	end
end

# This method connects all of the payment processing methods together.
def process_payment
	if transaction_ready
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
		@authorize_response = transaction.create_transaction(request)

		begin
			if @authorize_response.transactionResponse != nil

				# Capture the response variables for all transactions.
				@avs_code = response.transactionResponse.avsResultCode
				@cvv_code = response.transactionResponse.cvvResultCode

				# The transaction has a response.
				if transaction_ok
					@result = "OK"

					# CAPTURE the transaction details.
					@transaction_id = @authorize_response.transactionResponse.transId
					@transaction_response_code = @authorize_response.transactionResponse.responseCode

					if @transaction_response_code == "1"
						@authorize_response_kind = "Approved"
						@authorization_code = @authorize_response.transactionResponse.authCode
						@authorize_response_code = @authorize_response.messages.messages[0].code
						@authorize_response_message = @authorize_response.messages.messages[0].text

					elsif @transaction_response_code == "2"
						@authorize_response_kind = "Declined"
						@authorize_response_code = @authorize_response.transactionResponse.errors.errors[0].errorCode
						@authorize_response_error = @authorize_response.transactionResponse.errors.errors[0].errorText

					elsif @transaction_response_code == "3"
						@authorize_response_kind = "Error"
						@authorize_response_code = @authorize_response.transactionResponse.errors.errors[0].errorCode
						@authorize_response_error = @authorize_response.transactionResponse.errors.errors[0].errorText

					elsif @transaction_response_code == "4"
						@authorize_response_kind = "HeldforReview"
						@authorize_response_code = @authorize_response.transactionResponse.errors.errors[0].errorCode
						@authorize_response_error = @@authorize_response.transactionResponse.errors.errors[0].errorText
					end

				# A transactional ERROR occurred.
				elsif @authorize_response.messages.resultCode == MessageTypeEnum::Error
					@result = "ERROR"

					@authorize_response_kind = "TransactionError"
					@authorize_response_code = @authorize_response.transactionResponse.errors.errors[0].errorCode
					@authorize_response_error = @authorize_response.transactionResponse.errors.errors[0].errorText
				end

			# A transactional FAILURE occurred. [NIL]
			else
				@result = "ERROR"

				@authorize_response_kind = "TransactionFailure"
				@authorize_response_error = "A transactional FAILURE occurred."
			end

		rescue Errno::ETIMEDOUT => e
			@result = "ERROR"

			@authorize_response_kind = "TransactionFailure"
			@authorize_response_error = "Authorize.net isn't available."
		end
	end
end
