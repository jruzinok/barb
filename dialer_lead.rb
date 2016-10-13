def create_dialer_lead_customer_token
	find_dialer_lead

	if @dialer_lead_found == true && @has_customer_token == false
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

def find_dialer_lead
	@dialer_lead = DialerLead.find(:__p_DialerLeadID => @lead_id)

	if @dialer_lead[0] != nil
		@dialer_lead_found = true
		load_dialer_lead
	else
		@dialer_lead_found = false
		@statusCode = 300
		@statusMessage = "[ERROR] DialerLeadRecordNotFound"
		set_response
		log_error_to_console
	end
end

def load_dialer_lead
	@dialer_lead = @dialer_lead[0] # Load the record from the first position of the array.
	@namefirst = @dialer_lead["Name_First"]
	@serial = @dialer_lead["_Serial"].to_i
	@customer = "#{@database}#{@serial}" # The "ID" used to create a customer profile.
	@namelast = @dialer_lead["Name_Last"]
	@namefull = "#{@namefirst} #{@namelast}"
	@customer_token = @dialer_lead["Token_Profile_ID"]

	check_customer_token
end

def update_dialer_lead
	if @responseKind == "OK"
		@dialer_lead[:Token_Profile_ID] = @customer_token
	else
		@dialer_lead[:zzPP_Response] = @theResponse
		@dialer_lead[:zzPP_Response_Code] = @responseCode
		@dialer_lead[:zzPP_Response_Error] = @responseError
	end

	@dialer_lead.save
end
