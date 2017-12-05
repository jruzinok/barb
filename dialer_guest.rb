def create_dialer_guest_customer_token
	find_dialer_guest

	if @dialer_guest_found == true && @has_customer_token == false
		request = CreateCustomerProfileRequest.new
		request.profile = CustomerProfileType.new(@customer,@name_full,nil,nil,nil) #(merchantCustomerId,description,email,paymentProfiles,shipToList)

		@response = transaction.create_customer_profile(request)

		# The transaction has a response.
		if transaction_ok
			@customer_token = @response.customerProfileId
			@status_code = 200
			@status_message = "[OK] CustomerTokenCreated"
		else
			@status_code = 210
			@status_message = "[ERROR] CustomerTokenNotCreated"
			log_result_to_console
		end

		update_dialer_guest
		create_payment_processor_log
		set_response
		# clear_response
	end
end

def find_dialer_guest
	@dialer_guest = DIALERGuest.find(:__kP_Guest => @guest_id)

	if @dialer_guest[0] != nil
		@dialer_guest_found = true
		load_dialer_guest
	else
		@dialer_guest_found = false
		@status_code = 300
		@status_message = "[ERROR] DialerLeadRecordNotFound"
		set_response
		log_result_to_console
	end
end

def load_dialer_guest
	@dialer_guest = @dialer_guest[0] # Load the record from the first position of the array.
	@name_first = @dialer_guest["Name_First"]
	@serial = @dialer_guest["_Serial"].to_i
	@customer = "#{@database}#{@serial}" # The "ID" used to create a customer profile.
	@name_last = @dialer_guest["Name_Last"]
	@name_full = "#{@name_first} #{@name_last}"
	@customer_token = @dialer_guest["Token_Profile_ID"]

	check_customer_token
end

def update_dialer_guest
	if @response_kind == "OK"
		@dialer_guest[:Token_Profile_ID] = @customer_token
	else
		@dialer_guest[:zzPP_Response] = @response
		@dialer_guest[:zzPP_Response_Code] = @response_code
		@dialer_guest[:zzPP_Response_Error] = @response_error
	end

	@dialer_guest.save
end
