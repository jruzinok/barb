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



def batch_tokenize_directory_records
	find_directory_records_by_batch

	# This is used to mark the record's Date Processed.
	@today = Time.new

	# This outputs the batch id. It's used to display acts as the header or beginning of the process
	puts "\n\n\n\n\n"
	puts "----------------------------------------"
	puts "[DATABASE] #{@database}"
	puts "[CUSTOMER TOKINIZATION PROCESS]"
	puts "[BATCH] #{@batch}"
	puts "[TIMESTAMP] #{Time.now}"
	puts "----------------------------------------"

	@directories.each do |directory|
		@directory = directory
		# These "steps" are for clarity sake.
		# Later, these objects could be saved somewhere to log the steps of each batch when it's run.
		@step1 = load_directory
		@step2 = create_customer_token_by_batch
		@step3 = log_result_to_console_for_batch_tokenization

		# This prevents the record from being updated if a token wasn't created/attempted.
		if @flag_update_directory == true
			@step4 = update_directory
		end

		@step5 = clear_response
		@step6 = clear_batch_tokenization_variables
	end

end

def find_directory_records_by_batch
	if @database == "BC"
		@directories = DATADirectory.find(:zzD_Batch => @batch)
	elsif @database == "PTD"
		@directories = PTDDirectory.find(:zzD_Batch => @batch)
	end
end

def create_customer_token_by_batch
	if @has_customer_token == false
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
		end

		@flag_update_directory = true

	else
		@flag_update_directory = false

	end
end
