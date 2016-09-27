def create_customer_token
	find_directory

	if @directory_found == true && @has_customer_token == false
		request = CreateCustomerProfileRequest.new
		request.profile = CustomerProfileType.new(@serial,@namefull,nil,nil,nil) #(merchantCustomerId,description,email,paymentProfiles,shipToList)

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

		update_directory
		set_response
		clear_response
	end
end

def find_directory
	if @database == "BC"
		@directory = BCDirectory.find(:__kP_Directory => @directory_id)
	elsif @database == "PTD"
		@directory = PTDDirectory.find(:__kP_Directory => @directory_id)
	end

	if @directory[0] != nil
		@directory_found = true
		load_directory
	else
		@directory_found = false
		@statusCode = 300
		@statusMessage = "[ERROR] DirectoryRecordNotFound"
		set_response
		log_error_to_console
	end
end

def load_directory
	@directory = @directory[0] # Load the record from the first position of the array.
	@namefirst = @directory["Name_First"]
	@serial = @directory["_Serial"].to_i
	@namelast = @directory["Name_Last"]
	@namefull = "#{@namefirst} #{@namelast}"
	@customer_token = @directory["Token_Profile_ID"]

	check_customer_token
end

def check_customer_token
	if @customer_token != nil
		@has_customer_token = true
	else
		@has_customer_token = false
	end
end

def update_directory
	if @responseKind == "OK"
		@directory[:Token_Profile_ID] = @customer_token
	else
		@directory[:zzPP_Response] = @theResponse
		@directory[:zzPP_Response_Code] = @responseCode
		@directory[:zzPP_Response_Error] = @responseError
	end

	@directory.save
end
