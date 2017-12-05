def create_current_student_customer_token
	find_current_student

	if @current_student_found == true && @has_customer_token == false
		create_customer_token
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
		@status_code = 300
		@status_message = "[ERROR] CurrentStudentRecordNotFound"
		set_response
		log_result_to_console
	end
end

def load_current_student
	@name_first = @current_student["FIRST NAME"]
	@serial = @current_student["_Serial"].to_i
	@customer = "#{@database}#{@serial}" # The "ID" used to create a customer profile.
	@name_last = @current_student["LAST NAME"]
	@name_full = "#{@name_first} #{@name_last}"
	@customer_token = @current_student["Token_Profile_ID"]

	check_customer_token
end

def find_and_load_current_student_classdate
	@current_student = CURRENTSTUDENTCurrentStudent.find(:_Serial => @current_student_id)
	@current_student = @current_student[0] # Load the record from the first position of the array.
	@class_date = @current_student["__Current_Student | CLASS_ATTENDANCE ~ firstdate::Class_Date"]
end

def update_current_student
	if @response_kind == "OK"
		@current_student[:Token_Profile_ID] = @customer_token
	else
		@current_student[:zzPP_Response] = @response
		@current_student[:zzPP_Response_Code] = @response_code
		@current_student[:zzPP_Response_Error] = @response_error
	end

	@current_student.save
end
