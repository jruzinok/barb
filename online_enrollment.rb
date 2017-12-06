def create_oe_customer_token_logic
	if check_required_ct_params
		prepare_oe_customer_variables
		@check_by_merchant_id = true
		check_for_customer_profile

		if @has_profile == false && @result == "OK"
			prepare_oe_customer_variables
			create_oe_customer_token
		elsif @has_profile == true && @result == "OK"
			@result = "OK"
			@status_code = 230
			@status_message = "[OK] CustomerTokenAlreadyExisted"
			@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message,"customer_token"=>@customer_token][0]
		end

	else
		@result = "ERROR"
		@status_code = 194
		@status_message = "[ERROR] Missing required JSON variables."
		@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message][0]
	end
end

def create_oe_payment_token_logic
	if check_required_pt_params
		prepare_oe_payment_variables
		@check_by_customer_token = true
		check_for_customer_profile

		if @has_profile == true && @result == "OK"
			create_oe_payment_token
		else
			@result = "ERROR"
			@status_code = 195
			@status_message = "[ERROR] CustomerTokenDoesntExist"
			@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message][0]
		end

	else
		@result = "ERROR"
		@status_code = 193
		@status_message = "[ERROR] Missing required JSON variables."
		@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message][0]
	end
end

def list_oe_payment_token_logic
	if check_required_list_params
		prepare_oe_list_payment_variables
		@check_by_customer_token = true
		check_for_customer_profile

		if @has_profile == true && @result == "OK"
			@result = "OK"
			@status_code = 210
			@status_message = "[OK] PaymentTokensRetrieved"
			@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message,"customer_token"=>@customer_token,"payment_tokens"=>@tokens][0]
		else
			@result = "ERROR"
			@status_code = 194
			@status_message = "[ERROR] CustomerTokenDoesntExist"
			@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message][0]
		end

	else
		@result = "ERROR"
		@status_code = 192
		@status_message = "[ERROR] Missing required JSON variables."
		@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message][0]
	end
end

def check_for_customer_profile
	request = GetCustomerProfileRequest.new

	if @check_by_merchant_id == true
		request.merchantCustomerId = @customer
	elsif @check_by_customer_token == true
		request.customerProfileId = @customer_token
	end

	response = transaction.get_customer_profile(request)

	# Ensure that a response was received before proceeding.
	begin
		if response.messages != nil

			if transaction_ok
				# This is the expected result when the OE webapp requested to create a PT.
				@has_profile = true
				
				@customer_token = response.profile.customerProfileId
				@payment_tokens = response.profile.paymentProfiles

				if @payment_tokens.length >= 1
					@tokens = Array.new
					@i = 0

					@payment_tokens.each do |p|
						@tokens[@i] = {'payment_token' => p.customerPaymentProfileId, 'card_number'=> p.payment.creditCard.cardNumber}
						@i += 1
					end

				end

			else
				# This is the expected result when the OE webapp requested to create a CT.
				@has_profile = false
				@result = "OK"
			end

			# A transactional FAILURE occurred. [NIL]
		else
			@result = "ERROR"

			@response_kind = "TransactionFailure"
			@status_code = 198
			@status_message = "[ERROR] A transactional FAILURE occurred."
			@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message][0]
		end

	rescue Errno::ETIMEDOUT => e
		@result = "ERROR"

		@response_kind = "TransactionFailure"
		@status_code = 197
		@status_message = "[ERROR] Authorize.net isn't available."
		@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message][0]
	end
end

def check_required_ct_params
	if @json[:filemaker_id] && @json[:merchant] && @json[:name_first] && @json[:name_last] && @json[:program]
		true
	else
		false
	end
end

def check_required_pt_params
	if @json[:customer_token] && @json[:card_number] && @json[:card_mmyy] && @json[:card_cvv] && @json[:merchant] && @json[:name_first] && @json[:name_last]
		true
	else
		false
	end
end

def check_required_list_params
	if @json[:customer_token]
		true
	else
		false
	end
end

def prepare_oe_customer_variables
	@customer = "#{@json[:program]}#{@json[:filemaker_id]}" # The "ID" used to create a customer profile.
	@name_full = "#{@json[:name_first]} #{@json[:name_last]}"
end

def prepare_oe_list_payment_variables
	@customer_token = @json[:customer_token]
end

def prepare_oe_payment_variables
	@customer_token = @json[:customer_token]
	@name_first = @json[:name_first]
	@name_last = @json[:name_last]
	@card_number = @json[:card_number]
	@card_mmyy = @json[:card_mmyy]
	@card_cvv = @json[:card_cvv]
	@phone = @json[:phone_number]
	@address = @json[:address_street]
	@city = @json[:address_city]
	@state = @json[:address_state]
	@zip = @json[:address_zip]
end

def create_oe_customer_token
	create_customer_token
end

def create_oe_payment_token
	# Build the payment object
	payment = PaymentType.new(CreditCardType.new)
	payment.creditCard.cardNumber = @card_number
	payment.creditCard.expirationDate = @card_mmyy
	payment.creditCard.cardCode = @card_cvv

	# Build an address object
	billTo = CustomerAddressType.new
	billTo.firstName = @name_first
	billTo.lastName = @name_last
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
	request = CreateCustomerPaymentProfileRequest.new
	request.paymentProfile = paymentProfile
	request.customerProfileId = @customer_token

	@response = transaction.create_customer_payment_profile(request)

	# The transaction has a response.
	if transaction_ok
		@payment_token = @response.customerPaymentProfileId
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
