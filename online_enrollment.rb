def create_oe_customer_token_logic
	prepare_oe_customer_variables
	@check_by_merchant_id = true
	check_for_customer_profile

	if @has_profile == false && @resultCode == "OK"
		prepare_oe_customer_variables
		create_oe_customer_token
	end

end

def create_oe_payment_token_logic
	prepare_oe_payment_variables
	@check_by_customer_token = true
	check_for_customer_profile

	if @has_profile == true && @resultCode == "OK"
		create_oe_payment_token
	else
		@responseKind = "ERROR"
		@statusCode = 195
		@statusMessage = "[ERROR] CustomerTokenDoesntExist"
		@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage]
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
				@statusCode = 220
				@statusMessage = "[OK] CustomerTokenAlreadyExists"
				@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage,"customer_token"=>@customer_token,"payment_tokens"=>@payment_tokens]

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
			@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage]
		end

	rescue Errno::ETIMEDOUT => e
		@resultCode = "ERROR"

		@responseKind = "TransactionFailure"
		@statusCode = 197
		@statusMessage = "[ERROR] Authorize.net isn't available."
		@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage]
	end
end

def prepare_oe_customer_variables
	@customer = "#{@json[:program]}#{@json[:filemaker_id]}" # The "ID" used to create a customer profile.
	@namefull = "#{@json[:name_first]} #{@json[:name_last]}"
end

def prepare_oe_payment_variables
	@customer_token = @json[:customer_token]
	@namefirst = @json[:name_first]
	@namelast = @json[:name_last]
	@cardnumber = @json[:card_number]
	@carddate = @json[:card_mmyy]
	@cardcvv = @json[:card_cvv]
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
		@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage,"customer_token"=>@customer_token]
	else
		@responseKind = "ERROR"
		@responseCode = response.messages.messages[0].code
		@responseError = response.messages.messages[0].text
		@statusCode = 199 # Most likely caused by a '@customer' id issue.
		@statusMessage = "[ERROR] TokenIssue (Contact Admin)"
		@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage,"responseCode"=>@responseCode,"responseError"=>@responseError]
	end
end

def create_oe_payment_token
	request = CreateCustomerPaymentProfileRequest.new
	creditcard = CreditCardType.new(@cardnumber,@carddate,@cardcvv)
	payment = PaymentType.new(creditcard)
	profile = CustomerPaymentProfileType.new(nil,nil,payment,nil,nil)
	profile.billTo = CustomerAddressType.new
	profile.billTo.firstName = @namefirst
	profile.billTo.lastName = @namelast
	request.customerProfileId = @customer_token
	request.paymentProfile = profile

	response = transaction.create_customer_payment_profile(request)

	# The transaction has a response.
	if response.messages.resultCode == MessageTypeEnum::Ok
		@responseKind = "OK"
		@payment_token = response.customerPaymentProfileId
		@statusCode = 200
		@statusMessage = "[OK] PaymentTokenCreated"
		@maskedCardNumber = @cardnumber.split(//).last(4).join
		@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage,"payment_token"=>@payment_token,"cardnumber"=>@maskedCardNumber]
	else
		@responseKind = "ERROR"
		@responseCode = response.messages.messages[0].code
		@responseError = response.messages.messages[0].text
		@statusCode = 196
		@statusMessage = "[ERROR] PaymentTokenNotCreated"
		@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage,"responseCode"=>@responseCode,"responseError"=>@responseError]
	end

end
