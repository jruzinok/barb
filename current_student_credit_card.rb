def create_current_student_payment_token
	find_current_student
	find_credit_card
	create_current_student_payment_token_logic
 
	if @logic == "CreateCustomerToken"
		@preventloop = true
		create_current_student_customer_token
		create_current_student_payment_token

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

		update_credit_card
		create_payment_processor_log

	elsif @logic == "PaymentTokenAlreadyCreated"
		@statusCode = 220
		@statusMessage = "[ERROR] PaymentTokenAlreadyCreated"
		log_error_to_console
	end

	set_response
	clear_response
end

def create_current_student_payment_token_logic
	if @current_student_found == true && @has_customer_token == false && @preventloop != true
		@logic = "CreateCustomerToken"
	elsif @current_student_found == true && @has_customer_token == true && @credit_card_found == true && @has_payment_token == false
		@logic = "CreatePaymentToken"
	elsif @current_student_found == true && @has_customer_token == true && @credit_card_found == true && @has_payment_token == true
		@logic = "PaymentTokenAlreadyCreated"
	end
end

def find_credit_card
	if @database == "CS"
		@credit_card = CURRENTSTUDENTCreditCard.find(:__kp_Credit_Card_ID => @credit_card_id)
	end

	if @credit_card[0] != nil
		@credit_card_found = true
		@credit_card = @credit_card[0]
		load_credit_card
	else
		@credit_card_found = false
		@statusCode = 300
		@statusMessage = "[ERROR] PaymentMethodRecordNotFound"
		set_response
		log_error_to_console
	end
end

def load_credit_card
	@namefirst = @credit_card["__CURRENT_STUDENTS::FIRST NAME"]
	@namelast = @credit_card["__CURRENT_STUDENTS::LAST NAME"]
	@cardnumber = @credit_card["zzC_CreditCard_Number"]
	@carddate = @credit_card["zzC_MMYY"]
	@cardcvv = @credit_card["cvc"]
	@payment_token = @credit_card["Token_Payment_ID"]

	check_payment_token
end

def load_credit_card_by_batch
	@namefirst = @credit_card["__CURRENT_STUDENTS::FIRST NAME"]
	@namelast = @credit_card["__CURRENT_STUDENTS::LAST NAME"]
	@cardnumber = @credit_card["zzC_CreditCard_Number"]
	@carddate = @credit_card["zzC_MMYY"]
	@cardcvv = @credit_card["cvc"]
	@customer_token = @credit_card["__CURRENT_STUDENTS::Token_Profile_ID"]
	@payment_token = @credit_card["Token_Payment_ID"]

	check_customer_token
	check_payment_token
end

def update_credit_card
	if @responseKind == "OK"
		@credit_card[:Token_Payment_ID] = @payment_token
		@credit_card[:zzF_Status] = "Active"
		@credit_card[:zzF_Type] = "Token"
	else
		@credit_card[:zzPP_Response] = @theResponse
		@credit_card[:zzPP_Response_Code] = @responseCode
		@credit_card[:zzPP_Response_Error] = @responseError
		@credit_card[:zzF_Status] = "Inactive"
		@credit_card[:zzF_Type] = "Error"
	end

	@credit_card.save
end
