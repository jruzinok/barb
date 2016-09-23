def create_customer_token
	find_directory

	if @directory_found = true && @has_customer_token == false
		request = CreateCustomerProfileRequest.new
		request.profile = CustomerProfileType.new(@directory_id,@namefull,nil, nil)

		@response = transaction.create_customer_profile(request)

		# The transaction has a response.
		if @response.messages.resultCode == MessageTypeEnum::Ok
			@responseKind = "OK"
			@customer_token = @response.customerProfileId
		else
			@responseKind = "ERROR"
			@responseCode = @response.messages.messages[0].code
			@responseError = @response.messages.messages[0].text
		end

		update_directory
		clear_response
	end
end

def find_directory
	if @database == "BC"
		@directory = BCDirectory.find(:__kP_Directory => @directory_id)

		if @directory[0] != nil
			@directory_found = true
			load_directory
		else
			@directory_found = false
		end
	end
end

def load_directory
	@directory = @directory[0] # Load the record from the first position of the array.
	@namefirst = @directory["Name_First"]
	@namelast = @directory["Name_Last"]
	@namefull = @namefirst +" "+ @namelast
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
		@directory[:zzPP_Response] = @response
		@directory[:zzPP_Response_Code] = @responseCode
		@directory[:zzPP_Response_Error] = @responseError
	end

	@directory.save
end

def clear_response
	@response = ""
	@responseKind = ""
	@responseCode = ""
	@responseError = ""
end