def batch_tokenize_current_students
	find_current_students_by_batch

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

	@current_students.each do |cs|
		@current_student = cs
		# These "steps" are for clarity sake.
		# Later, these objects could be saved somewhere to log the steps of each batch when it's run.
		@step1 = load_current_student
		@step2 = create_current_student_customer_token_by_batch
		@step3 = log_result_to_console_for_batch_tokenization

		# This prevents the record from being updated if a token wasn't created/attempted.
		if @flag_update_current_student == true
			@step4 = update_current_student
		end

		@step5 = clear_response
		@step6 = clear_batch_tokenization_variables
	end

end

def find_current_students_by_batch
	@current_students = CURRENTSTUDENTCurrentStudent.find(:zzD_Batch => @batch)
end

def create_current_student_customer_token_by_batch
	if @has_customer_token == false
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
		end

		@flag_update_current_student = true

	else
		@flag_update_current_student = false

	end
end





def batch_tokenize_current_student_credit_cards
	find_current_student_credit_cards_by_batch

	# This is used to mark the record's Date Processed.
	@today = Time.new

	# This outputs the batch id. It's used to display acts as the header or beginning of the process
	puts "\n\n\n\n\n"
	puts "----------------------------------------"
	puts "[DATABASE] #{@database}"
	puts "[PAYMENT TOKINIZATION PROCESS]"
	puts "[BATCH] #{@batch}"
	puts "[TIMESTAMP] #{Time.now}"
	puts "----------------------------------------"

	@credit_cards.each do |cc|
		@credit_card = cc
		# These "steps" are for clarity sake.
		# Later, these objects could be saved somewhere to log the steps of each batch when it's run.
		@step1 = load_credit_card_by_batch
		@step2 = create_current_student_payment_token_by_batch
		@step3 = log_result_to_console_for_batch_tokenization

		# This prevents the record from being updated if a token wasn't created/attempted.
		if @flag_update_credit_card == true
			@step4 = update_credit_card
		end

		@step5 = clear_response
		@step6 = clear_batch_tokenization_variables
	end

end

def find_current_student_credit_cards_by_batch
	@credit_cards = CURRENTSTUDENTCreditCard.find(:zzD_Batch => @batch)
end

def create_current_student_payment_token_by_batch
	if @has_customer_token == true && @has_payment_token == false
		create_payment_token
		@flag_update_credit_card = true
	else
		@flag_update_credit_card = false
	end
end

def log_result_to_console_for_batch_tokenization
	puts "\n[RESULT] #{@result}"
	puts "[CUSTOMER TOKEN] #{@customer_token}"
	puts "[PAYMENT TOKEN] #{@payment_token}"
	puts "[MESSAGE] #{@status_message}"
	puts "[ERROR] #{@response_error}"
	puts "[CODE] #{@response_code}"
	puts "[RECORD] #{@serial}"
	puts "\n----------------------------------------"
end

def clear_batch_tokenization_variables
	@serial = nil
	@name_first = nil
	@name_last = nil
	@name_full = nil
	@customer = nil
	@customer_token = nil
	@payment_token = nil
end
