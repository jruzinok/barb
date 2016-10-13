def create_dialer_payment_token
 
	if @has_customer_token == true
		request = CreateCustomerPaymentProfileRequest.new
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

		save_dialer_payment_method
	end

	set_response
	clear_response
end

def find_dialer_payment_method
	@payment_method = DialerPaymentMethod.find(:__kP_PaymentMethod => @payment_method_id)

	if @payment_method[0] != nil
		@payment_method_found = true
		load_dialer_payment_method
	else
		@payment_method_found = false
		@statusCode = 300
		@statusMessage = "[ERROR] PaymentMethodRecordNotFound"
		set_response
		log_error_to_console
	end
end

def load_dialer_payment_method
	@payment_token = @payment_method["Token_Payment_ID"]

	check_payment_token
end

def save_dialer_payment_method
	if @responseKind == "OK"
		@dailer_payment_method = DialerPaymentMethod.new

		@dailer_payment_method[:_kF_DialerLead] = @lead_id
		@dailer_payment_method[:_kF_Guest] = @guest_id

		@dailer_payment[:Token_Payment_ID] = @payment_token

		@dailer_payment_method[:Name_First] = @namefirst
		@dailer_payment_method[:Name_Last] = @namelast
		@dailer_payment_method[:CreditCard_Number] = @cardnumber
		@dailer_payment_method[:MMYY] = @carddate
		@dailer_payment_method[:CVV] = @cardcvv
		@dailer_payment_method[:Address_Address] = @address
		@dailer_payment_method[:Address_City] = @city
		@dailer_payment_method[:Address_State] = @state
		@dailer_payment_method[:Address_Zip] = @zip
	else
		@dailer_payment_method[:zzPP_Response] = @theResponse
		@dailer_payment_method[:zzPP_Response_Code] = @responseCode
		@dailer_payment_method[:zzPP_Response_Error] = @responseError
	end

	@dailer_payment_method.save
end
