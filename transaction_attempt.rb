require 'bigdecimal'

def process_transaction_attempt

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
	puts "[TIMESTAMP] #{Time.now.utc.iso8601}"
	puts "----------------------------------------"

	find_directory
	find_payment_method

	process_onetime_payment
end

def process_onetime_payment
	@step1 = set_gl_codes

	if @directory_found == true && @payment_method_found == true	
		@step2 = card_or_token
		@step3 = process_payment
		@step4 = capture_response
		@step5 = save_transaction_attempt
		@step6 = create_payment_processor_log
	end

	@step7 = set_response
end

def capture_response
	if @resultCode == "OK"

		if @responseKind == "Approved"
			@statusCode = 200
			@statusMessage = "[OK] Transaction#{@responseKind}"
			log_result_to_console
		else # Declined, Error, & HeldforReview
			@statusCode = 205
			@statusMessage = "[ERROR] Transaction#{@responseKind}"
			log_error_to_console
		end

	else # Transactional Error (issue with CC or Authorize)
		@statusCode = 210
		@statusMessage = "[ERROR] #{@responseKind}"
		log_error_to_console
	end	
end

def save_transaction_attempt
	if @database == "BC" || @database == "CS"
		@transaction_attempt = DATATransactionAttempt.new
	elsif @database == "PTD"
		@transaction_attempt = PTDTransactionAttempt.new
	end

	# SAVE the response values for all transactions.
	@transaction_attempt[:zzPP_Transaction] = @transactionID
	@transaction_attempt[:zzPP_Response] = @theResponse
	@transaction_attempt[:zzPP_Response_AVS_Code] = @avsCode
	@transaction_attempt[:zzPP_Response_CVV_Code] = @cvvCode
	@transaction_attempt[:zzPP_Response_Code] = @responseCode

	# SET the foreign key fields.
	@transaction_attempt[:_kF_Directory] = @directory_id
	@transaction_attempt[:_kF_Statement] = @statement_id
	@transaction_attempt[:_kF_PaymentMethod] = @payment_method_id
	@transaction_attempt[:_kF_PaymentDate] = @payment_date_id # Sent when working Declined Payments.

	# RECORD the Transaction details.
	@transaction_attempt[:Amount] = @amount
	@transaction_attempt[:Date] = @date

	# Record the transaction results for each processed payment.
	if @resultCode == "OK"

		if @responseKind == "Approved" || @transactionResponseCode == "1"
			@transaction_attempt[:zzF_Status] = "Approved"
			@transaction_attempt[:zzPP_Authorization_Code] = @authorizationCode
			@transaction_attempt[:zzPP_Response_Message] = @responseMessage

		elsif @responseKind == "Declined" || @transactionResponseCode == "2"
			@transaction_attempt[:zzF_Status] = "Declined"
			@transaction_attempt[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "Error" || @transactionResponseCode == "3"
			@transaction_attempt[:zzF_Status] = "Error"
			@transaction_attempt[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "HeldforReview" || @transactionResponseCode == "4"
			@transaction_attempt[:zzF_Status] = "HeldForReview"
			@transaction_attempt[:zzPP_Response_Error] = @responseError
		end

	# These payments were NOT processes.
	elsif @resultCode == "ERROR"

		if @responseKind == "TransactionError"
			@transaction_attempt[:zzF_Status] = "Error"
			@transaction_attempt[:zzPP_Transaction] = @transactionID

			@transaction_attempt[:zzPP_Response] = @theResponse
			@transaction_attempt[:zzPP_Response_Code] = @responseCode
			@transaction_attempt[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "TokenError"
			@transaction_attempt[:zzF_Status] = "TokenError"
			@transaction_attempt[:zzPP_Response] = @theResponse
			@transaction_attempt[:zzPP_Response_Code] = @responseCode
			@transaction_attempt[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "TransactionFailure"
			@transaction_attempt[:zzF_Status] = "Failure"
			@transaction_attempt[:zzPP_Response_Error] = @responseError
		end
	end

	@transaction_attempt.save
end
