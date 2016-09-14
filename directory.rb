def create_customer_profile
	find_directory

	if @has_profile == false
		request = CreateCustomerProfileRequest.new
		request.profile = CustomerProfileType.new(@directory_id,@namefull,nil, nil)

		@response = transaction.create_customer_profile(request)

	# The transaction has a response.
	if @response.messages.resultCode == MessageTypeEnum::Ok
		@responseKind = "OK"
		@profile_id = @response.customerProfileId
	else
		@responseKind = "ERROR"
		@responseCode = @response.messages.messages[0].code
		@responseError = @response.messages.messages[0].text
	end

	update_directory
	clear_response
end

def find_directory
	if @database == "BC"
		@directory = BCDirectory.find(:__kP_Directory => @id)

		# Load the individual values.
		load_directory
	end
end

def load_directory
	@directory_id = @directory["__kP_Directory"]
	@namefirst = @directory["Name_First"]
	@namelast = @directory["Name_Last"]
	@namefull = @namefirst +" "+ @namelast
	@profile_id = @directory["Token_Profile_ID"]

	check_profile
end

def check_profile
	if @profile_id != nil
		@has_profile = true
	else
		@has_profile = false
	end
end

def update_directory
	if @responseKind == "OK"
		@directory[:Token_Profile_ID] = @profile_id
	else
		@directory[:zzPP_Response] = @response
		@directory[:zzPP_Response_Code] = @responseCode
		@directory[:zzPP_Response_Error] = @responseError
	end
end

	@directory.save
end

def clear_response
	@response = ""
	@responseKind = ""
	@responseCode = ""
	@responseError = ""
end