def create_current_student_customer_token
	find_current_student

	if @current_student_found == true && @has_customer_token == false
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
			log_result_to_console
		end

		update_current_student
		create_payment_processor_log
		set_response
		clear_response
	end
end

def find_current_student
	if @database == "CS"
		@current_student = CURRENTSTUDENTCurrentStudent.find(:_Serial => @current_student_id)
	end

	if @current_student[0] != nil
		@current_student_found = true
		@current_student = @current_student[0] # Load the record from the first position of the array.
		load_current_student
	else
		@current_student_found = false
		@statusCode = 300
		@statusMessage = "[ERROR] CurrentStudentRecordNotFound"
		set_response
		log_result_to_console
	end
end

def load_current_student
	@namefirst = @current_student["FIRST NAME"]
	@serial = @current_student["_Serial"].to_i
	@customer = "#{@database}#{@serial}" # The "ID" used to create a customer profile.
	@namelast = @current_student["LAST NAME"]
	@namefull = "#{@namefirst} #{@namelast}"
	@customer_token = @current_student["Token_Profile_ID"]

	check_customer_token
end

def find_and_load_current_student_classdate
	@current_student = CURRENTSTUDENTCurrentStudent.find(:_Serial => @current_student_id)
	@current_student = @current_student[0] # Load the record from the first position of the array.
	@classdate = @current_student["__Current_Student | CLASS_ATTENDANCE ~ firstdate::Class_Date"]
end

def update_current_student
	if @responseKind == "OK"
		@current_student[:Token_Profile_ID] = @customer_token
	else
		@current_student[:zzPP_Response] = @theResponse
		@current_student[:zzPP_Response_Code] = @responseCode
		@current_student[:zzPP_Response_Error] = @responseError
	end

	@current_student.save
end
