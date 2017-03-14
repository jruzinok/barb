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
		request = CreateCustomerPaymentProfileRequest.new
		creditcard = CreditCardType.new(@cardnumber,@carddate,@cardcvv)
		payment = PaymentType.new(creditcard)
		profile = CustomerPaymentProfileType.new(nil,nil,payment,nil,nil)
		profile.billTo = CustomerAddressType.new
		profile.billTo.firstName = @namefirst
		profile.billTo.lastName = @namelast
		request.customerProfileId = @customer_token
		request.paymentProfile = profile

		@theResponse = transaction.create_customer_payment_profile(request)

		# The transaction has a response.
		if @theResponse.messages.resultCode == MessageTypeEnum::Ok
			@responseKind = "OK"
			@payment_token = @theResponse.customerPaymentProfileId
			@statusCode = 200
			@statusMessage = "[OK] PaymentTokenCreated"
		else
			@responseKind = "ERROR"
			@responseCode = @theResponse.messages.messages[0].code
			@responseError = @theResponse.messages.messages[0].text
			@statusCode = 210
			@statusMessage = "[ERROR] PaymentTokenNotCreated"
		end

		@flag_update_credit_card = true

	else
		@flag_update_credit_card = false

	end

end

def log_result_to_console_for_batch_tokenization
	puts "\n[RESPONSE] #{@responseKind}"
	puts "[CUSTOMER TOKEN] #{@customer_token}"
	puts "[PAYMENT TOKEN] #{@payment_token}"
	puts "[MESSAGE] #{@statusMessage}"
	puts "[ERROR] #{@responseError}"
	puts "[CODE] #{@responseCode}"
	puts "[RECORD] #{@serial}"
	puts "\n----------------------------------------"
end

def clear_batch_tokenization_variables
	@serial = nil
	@namefirst = nil
	@namelast = nil
	@namefull = nil
	@customer = nil
	@customer_token = nil
	@payment_token = nil
end
