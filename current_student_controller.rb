def tokinize_current_students
	find_current_students_by_batch

	# This is used to mark the record's Date Processed.
	@today = Time.new

	# This outputs the batch id. It's used to display acts as the header or beginning of the process
	puts "\n\n\n\n\n"
	puts "----------------------------------------"
	puts "[DATABASE] #{@database}"
	puts "[CUSTOMER TOKINIZATION PROCESS]"
	puts "[BATCH] #{@batch}"
	puts "[TIMESTAMP] #{Time.now.utc.iso8601}"
	puts "----------------------------------------"

	@current_students.each do |cs|
		@current_student = cs
		# These "steps" are for clarity sake.
		# Later, these objects could be saved somewhere to log the steps of each batch when it's run.
		@step1 = load_current_student
		@step2 = create_current_student_customer_token_by_batch
		@step3 = log_result_to_console
		@step4 = update_current_student
		@step5 = create_payment_processor_log # EITHER update this or create a new method to create a log.
		@step6 = clear_response
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
			log_error_to_console
		end
	end
end





def tokinize_current_student_credit_cards
	find_current_student_credit_cards_by_batch

	# This is used to mark the record's Date Processed.
	@today = Time.new

	# This outputs the batch id. It's used to display acts as the header or beginning of the process
	puts "\n\n\n\n\n"
	puts "----------------------------------------"
	puts "[DATABASE] #{@database}"
	puts "[PAYMENT TOKINIZATION PROCESS]"
	puts "[BATCH] #{@batch}"
	puts "[TIMESTAMP] #{Time.now.utc.iso8601}"
	puts "----------------------------------------"

	@credit_cards.each do |cc|
		@credit_card = cc
		# These "steps" are for clarity sake.
		# Later, these objects could be saved somewhere to log the steps of each batch when it's run.
		@step1 = load_credit_card
		@step2 = process_or_skip
		@step3 = log_result_to_console
		@step4 = update_current_student
		@step5 = create_payment_processor_log
		@step6 = clear_response
	end

end

def find_current_student_credit_cards_by_batch
	@credit_cards = CURRENTSTUDENTCreditCard.find(:zzD_Batch => @batch)
end

def create_current_student_payment_token
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
			log_error_to_console
		end

		update_credit_card
		create_payment_processor_log

	end

end
