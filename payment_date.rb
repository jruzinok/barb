require 'bigdecimal'

def process_payment_dates
	find_by_batch

	# This outputs the batch id. It's used to display acts as the header or beginning of the process
	puts "\n\n\n\n\n"
	puts "\n----------------------------------------"
	puts "\n[DATABASE] #{@database}"
	puts "\n[BATCH] #{@batch})"
	puts "\n[TIMESTAMP] #{Time.now.utc.iso8601}"
	puts "\n----------------------------------------"

	# SET the GL Codes.
	@step0 = set_gl_codes

	@payment_dates.each do |pd|
		@payment_date = pd
		# These "steps" are for clarity sake.
		# Later, these objects could be saved somewhere to log the steps of each batch when it's run.
		@step1 = load_payment_date
		@step2 = process_or_skip
		@step3 = log_result_to_console
		@step4 = update_payment_date
		@step5 = clear_response
	end

	# This final step calls a script in either the Data File or PTD17 which in turn calls a Payment Processor Tool script in the Payment Processor application file.
	if @database == "PTD"
		@step6 = PTDPaymentDate.find({:_kF_PaymentBatch => @batch}, :post_script => ["PaymentProcessorCallBack", "#{@batch}\nInitiate from Ruby\nPTD"])
	elsif @database == "BC"
		@step6 = BCPaymentDate.find({:_kF_PaymentBatch => @batch}, :post_script => ["PaymentProcessorCallBack", "#{@batch}\nInitiate from Ruby\nBC"])
	end
end

def find_by_batch
	if @database == "PTD"
		@payment_dates = PTDPaymentDate.find(:_kF_PaymentBatch => @batch)
	elsif @database == "BC"
		@payment_dates = BCPaymentDate.find(:_kF_PaymentBatch => @batch)
	end
end

def load_payment_date
	@serial = @payment_date["_Serial"].to_i

	# TBD: CAPTURE the customer's and payment tokens.
	@customer_token = @payment_date["T54_DIRECTORY::Token_Profile_ID"]
	@payment_token = @payment_date["T54_PAYMENTMETHOD::Token_Payment_ID"]

	# Credit Card values.
	@cardnumber = @payment_date["T54_PAYMENTMETHOD::CreditCard_Number"]
	@carddate = @payment_date["T54_PAYMENTMETHOD::MMYY"]
	@cardcvv = @payment_date["T54_PAYMENTMETHOD::CVV"]

	# Transaction details.
	@amount = @payment_date["Amount"].to_f

	if @database == "BC"
		@bc = @payment_date["T54_LINK::zzC_BC_Location_ABBR"]
	end

end

def update_payment_date
		# SAVE the response values for all transactions.

	# Record the transaction results for each processed payment.
	if @resultCode == "OK"
		@payment_date[:zzPP_Transaction] = @transactionID

		@payment_date[:zzPP_Response] = @theResponse
		@payment_date[:zzPP_Response_AVS_Code] = @avsCode
		@payment_date[:zzPP_Response_CVV_Code] = @cvvCode

		@payment_date[:zzPP_Response_Code] = @responseCode

		if @responseKind == "Approved" || @transactionResponseCode == "1"
			@payment_date[:zzF_Status] = "Approved"
			@payment_date[:zzPP_Authorization_Code] = @authorizationCode
			@payment_date[:zzPP_Response_Message] = @responseMessage

		elsif @responseKind == "Declined" || @transactionResponseCode == "2"
			@payment_date[:zzF_Status] = "Declined"
			@payment_date[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "Error" || @transactionResponseCode == "3"
			@payment_date[:zzF_Status] = "Error"
			@payment_date[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "HeldforReview" || @transactionResponseCode == "4"
			@payment_date[:zzF_Status] = "HeldForReview"
			@payment_date[:zzPP_Response_Error] = @responseError
		end

	# These payments were NOT processes.
	else
		if @responseKind == "TransactionError"
			@payment_date[:zzF_Status] = "Error"
			@payment_date[:zzPP_Transaction] = @transactionID

			@payment_date[:zzPP_Response] = @theResponse
			@payment_date[:zzPP_Response_Code] = @responseCode
			@payment_date[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "TokenError"
			@payment_date[:zzPP_Response] = @theResponse
			@payment_date[:zzPP_Response_Code] = @responseCode
			@payment_date[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "TransactionFailure"
			@payment_date[:zzPP_Response_Error] = @responseError
		end
	end

	@payment_date.save
end
