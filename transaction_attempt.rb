require 'bigdecimal'

def process_transaction_attempt

	# This is used to determine the GL Code for Current Student Payment Dates.
	@today = Time.new

	# This outputs the details of this Transacion Attempt to the console.
	puts "\n\n\n\n\n"
	puts "----------------------------------------"
	puts "[PROCESS] TRANSACTION ATTEMPT"
	puts "[DATABASE] #{@database}"
	puts "[DIRECTORY] #{@directory_id}"
	puts "[PAYMENTMETHOD] #{@payment_method_id}"
	puts "[PAYMENTDATE] #{@payment_date_id}"
	puts "[DATE] #{@date}"
	puts "[AMOUNT] #{@amount}"
	puts "[TIMESTAMP] #{Time.now}"
	puts "----------------------------------------"

	find_directory
	find_payment_method

	if @directory_found == true && @payment_method_found == true

		# CAPTURE additional data needed to determine the GL Codes.
		if @database == "BC"
			find_event_attendee_by_directory
		elsif @database == "CS"
			load_directory_current_student_data
			find_and_load_current_student_classdate
		elsif @database == "PTD"
			# NOT YET SETUP/ISN'T NEEDED AT THIS TIME. 2/23/2017
		end

		check_directory_and_payment_method_merchants
		set_gl_codes
		process_or_skip
		capture_response
		save_transaction_attempt
		create_payment_processor_log
		set_response
	end
end

def capture_response
	if @result == "OK"

		if @authorize_response_kind == "Approved"
			@status_code = 200
			@status_message = "[OK] Transaction#{@authorize_response_kind}"
			log_result_to_console
		else # Declined, Error, & HeldforReview
			@status_code = 205
			@status_message = "[ERROR] Transaction#{@authorize_response_kind}"
			log_result_to_console
		end

	else # Transactional Error (issue with CC or Authorize)
		@status_code = 210
		@status_message = "[ERROR] #{@authorize_response_kind}"
		log_result_to_console
	end	
end

def save_transaction_attempt
	if @database == "BC" || @database == "CS"
		@transaction_attempt = DATATransactionAttempt.new
	elsif @database == "PTD"
		@transaction_attempt = PTDTransactionAttempt.new
	end

	# SAVE the response values for all transactions.
	@transaction_attempt[:zzPP_Transaction] = @transaction_id
	@transaction_attempt[:zzPP_Response] = @authorize_response
	@transaction_attempt[:zzPP_Response_AVS_Code] = @avs_code
	@transaction_attempt[:zzPP_Response_CVV_Code] = @cvv_code
	@transaction_attempt[:zzPP_Response_Code] = @authorize_response_code

	# SET the foreign key fields.
	@transaction_attempt[:_kF_Directory] = @directory_id
	@transaction_attempt[:_kF_Statement] = @statement_id
	@transaction_attempt[:_kF_PaymentMethod] = @payment_method_id
	@transaction_attempt[:_kF_PaymentDate] = @payment_date_id # Sent when working Declined Payments.

	# RECORD the Transaction details.
	@transaction_attempt[:Amount] = @amount
	@transaction_attempt[:Date] = @date

	# Record the transaction results for each processed payment.
	if @result == "OK"
		@transaction_attempt[:zzF_Status] = @authorize_response_kind

		if @authorize_response_kind == "Approved"
			@transaction_attempt[:zzPP_Authorization_Code] = @authorization_code
			@transaction_attempt[:zzPP_Response_Message] = @authorize_response_message
		else
			@transaction_attempt[:zzPP_Response_Error] = @authorize_response_message
		end

	elsif @result == "ERROR"

		@transaction_attempt[:zzF_Status] = @authorize_response_kind
		@transaction_attempt[:zzPP_Transaction] = @transaction_id
		@transaction_attempt[:zzPP_Response] = @authorize_response
		@transaction_attempt[:zzPP_Response_Code] = @authorize_response_code
		@transaction_attempt[:zzPP_Response_Error] = @authorize_response_message

	end

	@transaction_attempt.save
end
