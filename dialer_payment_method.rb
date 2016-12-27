def create_dialer_payment_token
	find_dialer_lead
 
	if @has_customer_token == true
		request = CreateCustomerPaymentProfileRequest.new
		creditcard = CreditCardType.new(@cardnumber,@carddate,@cardcvv)
		payment = PaymentType.new(creditcard)
		profile = CustomerPaymentProfileType.new(nil,nil,payment,nil,nil)
		profile.billTo = CustomerAddressType.new
		profile.billTo.firstName = @namefirstCC
		profile.billTo.lastName = @namelastCC
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
		create_payment_processor_log
	end

	# This sends the PaymentMethodID back to the Dialer php web app in the response body.
	if @responseKind == "OK" && @payment_method_found == true
		@statusMessage = @payment_method_id.to_s
	end

	set_response
	# clear_response
end

def find_dialer_payment_method
	@payment_method = DIALERPaymentMethod.find(:__kP_PaymentMethod => @payment_method_id)

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

def find_dialer_payment_method_by_payment_token
	@payment_method = DIALERPaymentMethod.find(:Token_Payment_ID => @payment_token)

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
	@payment_method = @payment_method[0] # Load the record from the first position of the array.
	@payment_method_id = @payment_method["__kP_PaymentMethod"]
	@payment_token = @payment_method["Token_Payment_ID"]

	check_payment_token
end

def save_dialer_payment_method
	@dailer_payment_method = DIALERPaymentMethod.new

	@dailer_payment_method[:_kF_DialerLead] = @lead_id
	@dailer_payment_method[:_kF_Guest] = @guest_id
	@dailer_payment_method[:Name_First] = @namefirstCC
	@dailer_payment_method[:Name_Last] = @namelastCC
	@dailer_payment_method[:CreditCard_Number] = @cardnumber
	@dailer_payment_method[:MMYY] = @carddate
	@dailer_payment_method[:CVV] = @cardcvv

	if @responseKind == "OK"
		@dailer_payment_method[:Token_Payment_ID] = @payment_token
	else
		@dailer_payment_method[:zzPP_Response] = @theResponse
		@dailer_payment_method[:zzPP_Response_Code] = @responseCode
		@dailer_payment_method[:zzPP_Response_Error] = @responseError
	end

	@dailer_payment_method.save

	# GRAB the ID from the newly created PaymentMethod.
	if @responseKind == "OK"
		find_dialer_payment_method_by_payment_token
	end
end
