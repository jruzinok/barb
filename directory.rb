def create_customer_token_logic
	find_directory

	if @directory_found == true && @has_customer_token == false
		@skip_find_directory = true # This prevents the find routine from hitting the database again (to speed the process up and make it less db intensive).
		create_customer_token

		if @responseKind == "OK"
			@customer_token_ready = true
		end

	elsif @directory_found == true && @has_customer_token == true
		@customer_token_ready = true
		@statusCode = 220
		@statusMessage = "[OK] CustomerTokenAlreadyExists"
		@skip_find_directory = true
	end

	set_response
end

def create_customer_token
	unless @skip_find_directory == true
		find_directory
	end

	if @directory_found == true && @has_customer_token == false
		request = CreateCustomerProfileRequest.new
		request.profile = CustomerProfileType.new(@customer,@namefull,nil,nil,nil) #(merchantCustomerId,description,email,paymentProfiles,shipToList)

		@theResponse = transaction.create_customer_profile(request)

		# The transaction has a response.
		if @theResponse.messages.resultCode == MessageTypeEnum::Ok
			@responseKind = "OK"
			@customer_token = @theResponse.customerProfileId
			@has_customer_token = true
			@statusCode = 200
			@statusMessage = "[OK] CustomerTokenCreated"
		else
			@responseKind = "ERROR"
			@responseCode = @theResponse.messages.messages[0].code
			@responseError = @theResponse.messages.messages[0].text
			@statusCode = 199 # Most likely caused by a '@customer' id issue.
			@statusMessage = "[ERROR] TokenIssue (Contact Admin)"
			log_result_to_console
		end

		update_directory
		create_payment_processor_log
		set_response
	end
end

def find_directory
	if @database == "DATA" || @database == "BC" || @database == "CS"
		@directory = DATADirectory.find(:__kP_Directory => @directory_id)
	elsif @database == "PTD"
		@directory = PTDDirectory.find(:__kP_Directory => @directory_id)
	end

	if @directory[0] != nil
		@directory_found = true
		@directory = @directory[0] # Load the record from the first position of the array.
		load_directory
	else
		@directory_found = false
		@statusCode = 300
		@statusMessage = "[ERROR] DirectoryRecordNotFound"
		set_response
		log_result_to_console
	end
end

def load_directory
	@namefirst = @directory["Name_First"]
	@serial = @directory["_Serial"].to_i
	@customer = "#{@database}#{@serial}" # The "ID" used to create a customer profile.
	@namelast = @directory["Name_Last"]
	@namefull = "#{@namefirst} #{@namelast}"
	@customer_token = @directory["Token_Profile_ID"]

	check_customer_token
end

def load_directory_current_student_data
	@current_student_id = @directory["_kF_Current_Student"]
	@invoice = @directory["Number_Invoice_GL"]
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
