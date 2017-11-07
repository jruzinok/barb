def create_oe_customer_token_logic
	prepare_oe_variables
	check_for_customer_profile

	if @has_profile == false && @resultCode == "OK"
		prepare_oe_variables
		create_oe_customer_token
	end

end

def check_for_customer_profile
	# @customer_token = '1898613915'
	# @filemaker_id = 'DL8748015'

	request = GetCustomerProfileRequest.new
	# request.customerProfileId = @customer_token
	request.merchantCustomerId = @customer

	response = transaction.get_customer_profile(request)

	# Ensure that a response was received before proceeding.
	begin
		if response.messages != nil

			if response.messages.resultCode == MessageTypeEnum::Ok
				@has_profile = true
				@resultCode = "OK"

				@customer_token = response.profile.customerProfileId
				@payment_tokens = response.profile.paymentProfiles
				@statusCode = 220
				@statusMessage = "[OK] CustomerTokenAlreadyExists"
				@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage,"customer_token"=>@customer_token,"payment_tokens"=>@payment_tokens]

			else
				# This is the expected result; the OE webapp requested a CT be created.
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

def prepare_oe_variables
	@customer = "#{@program}#{@filemaker_id}" # The "ID" used to create a customer profile.
	# @namefull = "#{@json[:Name_First]} #{@json[:Name_Last]}"
	@namefull = "Dono Korb"
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
		@return_json_package = JSON.generate ["responseKind"=>@responseKind,"statusCode"=>@statusCode,"statusMessage"=>@statusMessage]
	end
end
