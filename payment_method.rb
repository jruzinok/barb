def create_payment_token
	find_directory
	find_payment_method
	create_payment_token_logic
 
	if @logic == "CreateCustomerToken"
		@preventloop = true
		create_customer_token
		create_payment_token

	elsif @logic == "CreatePaymentToken"
		request = CreateCustomerPaymentProfileRequest.new
		creditcard = CreditCardType.new(@cardnumber,@carddate,@cardcvv)
		payment = PaymentType.new(creditcard)
		profile = CustomerPaymentProfileType.new(nil,nil,payment,nil,nil)
		profile.billTo = CustomerAddressType.new
		profile.billTo.firstName = @namefirst
		profile.billTo.lastName = @namelast
		request.customerProfileId = @customer_token
		request.paymentProfile = profile

		@theResponse = transaction.create_customer_payment_profile(request)

		# The transaction has a response.
		if @theResponse.messages.resultCode == MessageTypeEnum::Ok
			@responseKind = "OK"
			@payment_token = @theResponse.customerPaymentProfileId
			@statusCode = 200
			@statusMessage = "[OK] PaymentTokenCreated"
		else
			@responseKind = "ERROR"
			@responseCode = @theResponse.messages.messages[0].code
			@responseError = @theResponse.messages.messages[0].text
			@statusCode = 210
			@statusMessage = "[ERROR] PaymentTokenNotCreated"
			log_error_to_console
		end

		update_payment_method

	elsif @logic == "PaymentTokenAlreadyCreated"
		@statusCode = 220
		@statusMessage = "[ERROR] PaymentTokenAlreadyCreated"
		log_error_to_console
	end

	set_response
	clear_response
end

def create_payment_token_logic
	if @directory_found == true && @has_customer_token == false && @preventloop != true
		@logic = "CreateCustomerToken"
	elsif @directory_found == true && @has_customer_token == true && @payment_method_found == true && @has_payment_token == false
		@logic = "CreatePaymentToken"
	elsif @directory_found == true && @has_customer_token == true && @payment_method_found == true && @has_payment_token == true
		@logic = "PaymentTokenAlreadyCreated"
	end
end

def find_payment_method
	if @database == "BC"
		@payment_method = BCPaymentMethod.find(:__kP_PaymentMethod => @payment_method_id)
	elsif @database == "PTD"
		@payment_method = PTDPaymentMethod.find(:__kP_PaymentMethod => @payment_method_id)
	end

	if @payment_method[0] != nil
		@payment_method_found = true
		load_payment_method
	else
		@payment_method_found = false
		@statusCode = 300
		@statusMessage = "[ERROR] PaymentMethodRecordNotFound"
		set_response
		log_error_to_console
	end
end

def load_payment_method
	@payment_method = @payment_method[0]
	@namefirst = @payment_method["Name_First"]
	@namelast = @payment_method["Name_Last"]
	@payment_token = @payment_method["Token_Payment_ID"]

	check_payment_token
end

def update_payment_method
	if @responseKind == "OK"
		@payment_method[:Token_Payment_ID] = @payment_token
		@payment_method[:zzF_Status] = "Active"
		@payment_method[:zzF_Type] = "Token"
	else
		@payment_method[:zzPP_Response] = @theResponse
		@payment_method[:zzPP_Response_Code] = @responseCode
		@payment_method[:zzPP_Response_Error] = @responseError
		@payment_method[:zzF_Status] = "Inactive"
		@payment_method[:zzF_Type] = "Error"
	end

	@payment_method.save
end
