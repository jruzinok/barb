def create_payment_token
	find_directory
	find_payment_method

	if @directory_found = true && @has_customer_token == true && @payment_method_found = true && @has_payment_token == false
		request = CreateCustomerPaymentProfileRequest.new
		request.customerProfileId = @customer_token
		creditcard = CreditCardType.new(@cardnumber,@carddate,@cardcvv)
		payment = PaymentType.new(creditcard)
		profile = CustomerPaymentProfileType.new(nil,nil,payment,nil,nil)
		profile.billTo = CustomerAddressType.new
		profile.billTo.firstName = @namefirst
		profile.billTo.lastName = @namelast
		profile.billTo.address = @address
		profile.billTo.city = @city
		profile.billTo.state = @state
		profile.billTo.zip = @zip
		request.paymentProfile = profile

		@response = transaction.create_customer_payment_profile(request)

		# The transaction has a response.
		if @response.messages.resultCode == MessageTypeEnum::Ok
			@responseKind = "OK"
			@payment_token = @response.customerPaymentProfileId
		else
			@responseKind = "ERROR"
			@responseError = @response.messages.messages[0].text
		end

		update_payment_method
		clear_response
	end
end

def find_payment_method
	if @database == "BC"
		@payment_method = BCPaymentMethod.find(:__kP_PaymentMethod => @payment_method_id)

		if @payment_method[0] != nil
			@payment_method_found = true
			load_payment_method
		else
			@payment_method_found = false
		end
	end
end

def load_payment_method
	@namefirst = @payment_method["Name_First"]
	@namelast = @payment_method["Name_Last"]
	@address = @payment_method["T55_CONTACTINFO::Add_Address1"]
	@city = @payment_method["T55_CONTACTINFO::Add_City"]
	@state = @payment_method["T55_CONTACTINFO::Add_State"]
	@zip = @payment_method["T55_CONTACTINFO::Add_Zip"]
	@payment_token = @payment_method["Token_Payment_ID"]

	check_payment_token
end

def check_payment_token
	if @payment_token != nil
		@has_payment_token = true
	else
		@has_payment_token = false
	end
end

def update_payment_method
	if @responseKind == "OK"
		@payment_method[:Token_Payment_ID] = @payment_token
	else
		@payment_method[:zzPP_Response] = @response
		@payment_method[:zzPP_Response_Error] = @responseError
	end

	@payment_method.save
end

def clear_response
	@response = ""
	@responseKind = ""
	@responseError = ""
end