def create_oe_customer_token_logic
	if check_required_ct_params
		prepare_oe_customer_variables
		@check_by_merchant_id = true
		check_for_customer_profile

		if @has_profile == false && @resultCode == "OK"
			prepare_oe_customer_variables
			create_oe_customer_token
		end

	else
		@responseKind = "ERROR"
		@statusCode = 194
		@statusMessage = "[ERROR] Missing required JSON variables."
		@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage][0]
	end
end

def create_oe_payment_token_logic
	if check_required_pt_params
		prepare_oe_payment_variables
		@check_by_customer_token = true
		check_for_customer_profile

		if @has_profile == true && @resultCode == "OK"
			create_oe_payment_token
		else
			@responseKind = "ERROR"
			@statusCode = 195
			@statusMessage = "[ERROR] CustomerTokenDoesntExist"
			@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage][0]
		end

	else
		@responseKind = "ERROR"
		@statusCode = 193
		@statusMessage = "[ERROR] Missing required JSON variables."
		@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage][0]
	end
end

def list_oe_payment_token_logic
	if check_required_list_params
		prepare_oe_list_payment_variables
		@check_by_customer_token = true
		check_for_customer_profile

		if @has_profile == true && @resultCode == "OK"
			@statusCode = 210
			@statusMessage = "[OK] PaymentTokensRetrieved"
			@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage,"customer_token"=>@customer_token,"payment_tokens"=>@tokens,"cards"=>@cards][0]
		else
			@responseKind = "ERROR"
			@statusCode = 194
			@statusMessage = "[ERROR] CustomerTokenDoesntExist"
			@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage][0]
		end

	else
		@responseKind = "ERROR"
		@statusCode = 192
		@statusMessage = "[ERROR] Missing required JSON variables."
		@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage][0]
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

			if response.messages.resultCode == MessageTypeEnum::Ok
				# This is the expected result when the OE webapp requested to create a PT.
				@has_profile = true
				@resultCode = "OK"
				
				@customer_token = response.profile.customerProfileId
				@payment_tokens = response.profile.paymentProfiles

				if @payment_tokens.length >= 1
					@tokens = Array.new
					@cards = Array.new
					@i = 0

					@payment_tokens.each do |p|
						@tokens[@i] = p.customerPaymentProfileId
						@cards[@i] = p.payment.creditCard.cardNumber
						@i += 1
					end

				end

			else
				# This is the expected result when the OE webapp requested to create a CT.
				@has_profile = false
				@resultCode = "OK"
			end

			# A transactional FAILURE occurred. [NIL]
		else
			@resultCode = "ERROR"

			@responseKind = "TransactionFailure"
			@statusCode = 198
			@statusMessage = "[ERROR] A transactional FAILURE occurred."
			@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage][0]
		end

	rescue Errno::ETIMEDOUT => e
		@resultCode = "ERROR"

		@responseKind = "TransactionFailure"
		@statusCode = 197
		@statusMessage = "[ERROR] Authorize.net isn't available."
		@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage][0]
	end
end

def check_required_ct_params
	if @json[:program] && @json[:filemaker_id] && @json[:name_first] && @json[:name_last]
		true
	else
		false
	end
end

def check_required_pt_params
	if @json[:customer_token] && @json[:name_first] && @json[:name_last] && @json[:card_number] && @json[:card_mmyy] && @json[:card_cvv]
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
	@namefull = "#{@json[:name_first]} #{@json[:name_last]}"
end

def prepare_oe_list_payment_variables
	@customer_token = @json[:customer_token]
end

def prepare_oe_payment_variables
	@customer_token = @json[:customer_token]
	@namefirst = @json[:name_first]
	@namelast = @json[:name_last]
	@cardnumber = @json[:card_number]
	@cardmmyy = @json[:card_mmyy]
	@cardcvv = @json[:card_cvv]
	@phone = @json[:phone_number]
	@address = @json[:address_street]
	@city = @json[:address_city]
	@state = @json[:address_state]
	@zip = @json[:address_zip]
end

def create_oe_customer_token
	request = CreateCustomerProfileRequest.new
	request.profile = CustomerProfileType.new(@customer,@namefull,nil,nil,nil) #(merchantCustomerId,description,email,paymentProfiles,shipToList)

	response = transaction.create_customer_profile(request)

	# The transaction has a response.
	if response.messages.resultCode == MessageTypeEnum::Ok
		@responseKind = "OK"
		@customer_token = response.customerProfileId
		@statusCode = 200
		@statusMessage = "[OK] CustomerTokenCreated"
		@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage,"customer_token"=>@customer_token][0]
	else
		@responseKind = "ERROR"
		@responseCode = response.messages.messages[0].code
		@responseError = response.messages.messages[0].text
		@statusCode = 199 # Most likely caused by a '@customer' id issue.
		@statusMessage = "[ERROR] TokenIssue (Contact Admin)"
		@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage,"responseCode"=>@responseCode,"responseError"=>@responseError][0]
	end
end

def create_oe_payment_token
	# Build the payment object
	payment = PaymentType.new(CreditCardType.new)
	payment.creditCard.cardNumber = @cardnumber
	payment.creditCard.expirationDate = @cardmmyy
	payment.creditCard.cardCode = @cardcvv

	# Build an address object
	billTo = CustomerAddressType.new
	billTo.firstName = @namefirst
	billTo.lastName = @namelast
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

	response = transaction.create_customer_payment_profile(request)

	# The transaction has a response.
	if response.messages.resultCode == MessageTypeEnum::Ok
		@responseKind = "OK"
		@payment_token = response.customerPaymentProfileId
		@statusCode = 200
		@statusMessage = "[OK] PaymentTokenCreated"
		@maskedCardNumber = @cardnumber.split(//).last(4).join
		@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage,"payment_token"=>@payment_token,"cardnumber"=>@maskedCardNumber][0]
	else
		@responseKind = "ERROR"
		@responseCode = response.messages.messages[0].code
		@responseError = response.messages.messages[0].text
		@statusCode = 196
		@statusMessage = "[ERROR] PaymentTokenNotCreated"
		@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage,"responseCode"=>@responseCode,"responseError"=>@responseError][0]
	end

end
