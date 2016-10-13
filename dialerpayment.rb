def process_create_dialier_payment_request
	parse_create_dialer_payment_post

	if @requestType == "Charge"
		create_dialer_tokens
		process_dialer_payment
	elsif @requestType == "Schedule"
		create_dialer_tokens
	end

	# Save the results into FileMaker.
	save_dailerpayment
end

def parse_create_dialer_payment_post
	@lead_id = params[:lead_id]
	@guest_id = params[:guest_id]
	@requestType = params[:requestType]

	# Grab the values from the POST object.
	@date = @params[:Date]
	@amount = @params[:Amount]
	
	@namefirst = params[:Name_First]
	@namelast = params[:Name_Last]
	@cardnumber = params[:CreditCard]
	@carddate = params[:MMYY]
	@cardcvv = params[:CVV]
	@address = params[:Address_Address]
	@city = params[:Address_City]
	@state = params[:Address_State]
	@zip = params[:Address_Zip]
end

def create_dialer_customer_token
	find_dialier_lead

	if @dialier_lead_found == true && @has_customer_token == false
		request = CreateCustomerProfileRequest.new
		request.profile = CustomerProfileType.new(@customer,@namefull,nil,nil,nil) #(merchantCustomerId,description,email,paymentProfiles,shipToList)

		@theResponse = transaction.create_customer_profile(request)

		# The transaction has a response.
		if @theResponse.messages.resultCode == MessageTypeEnum::Ok
			@responseKind = "OK"
			@customer_token = @theResponse.customerProfileId
			@statusCode = 200
			@statusMessage = "[OK] CustomerTokenCreated"
		else
			@responseKind = "ERROR"
			@responseCode = @theResponse.messages.messages[0].code
			@responseError = @theResponse.messages.messages[0].text
			@statusCode = 210
			@statusMessage = "[ERROR] CustomerTokenNotCreated"
			log_error_to_console
		end

		update_dialier_lead
		set_response
		clear_response
	end
end

def save_dailerpayment
	if @responseKind == "OK"
		@dailerleadpayment = DialerPayment.new

		@dailerleadpayment[:_kF_DialerLead] = @lead_id
		@dailerleadpayment[:_kF_Guest] = @guest_id

		@dailerleadpayment[:Token_Profile_ID] = @customer_token
		@dailerleadpayment[:Token_Payment_ID] = @payment_token

		@dailerleadpayment[:Date] = @date
		@dailerleadpayment[:Amount] = @amount
		
		@dailerleadpayment[:Name_First] = @namefirst
		@dailerleadpayment[:Name_Last] = @namelast
		@dailerleadpayment[:CreditCard_Number] = @cardnumber
		@dailerleadpayment[:MMYY] = @carddate
		@dailerleadpayment[:CVV] = @cardcvv
		@dailerleadpayment[:Address_Address] = @address
		@dailerleadpayment[:Address_City] = @city
		@dailerleadpayment[:Address_State] = @state
		@dailerleadpayment[:Address_Zip] = @zip
	else
		@dailerleadpayment[:zzPP_Response] = @theResponse
		@dailerleadpayment[:zzPP_Response_Code] = @responseCode
		@dailerleadpayment[:zzPP_Response_Error] = @responseError
	end

	@dailerleadpayment.save
end
