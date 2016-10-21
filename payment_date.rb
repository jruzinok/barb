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

	# This final step calls the Payment Processor Tool script in the Payment Processor application file.
	# @step6 = BCPaymentDate.find({:_kF_PaymentBatch => @batch}, :post_script => ["PaymentProcessorCallBack", "#{@batch}\nInitiate from Ruby"])
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
	@namefirst = @payment_date["T54_Link | DIRECTORY ~ contestant::Name_First"]
	@namelast = @payment_date["T54_Link | DIRECTORY ~ contestant::Name_Last"]

	# Address values.
	@address = @payment_date["T54_PaymentMethod | CONTACTINFO::Add_Address1"]
	@city = @payment_date["T54_PaymentMethod | CONTACTINFO::Add_City"]
	@state = @payment_date["T54_PaymentMethod | CONTACTINFO::Add_State"]
	@zip = @payment_date["T54_PaymentMethod | CONTACTINFO::Add_Zip"]

	# TBD: CAPTURE the customer's profile id and payment id.
	@customer_token = @payment_date["T54_DIRECTORY::Token_Profile_ID"]
	@payment_token = @payment_date["T54_PAYMENTMETHOD::Token_Payment_ID"]

	# Credit Card values.
	@cardnumber = @payment_date["T54_PAYMENTMETHOD::CreditCard_Number"]
	@carddate = @payment_date["T54_PAYMENTMETHOD::MMYY"]
	@cardcvv = @payment_date["T54_PAYMENTMETHOD::CVV"]

	# Transaction details.
	@amount = @payment_date["Amount"].to_f
	@bc = @payment_date["T54_LINK::zzC_BC_Location_ABBR"]
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

		if @responseKind == "Approved"
			@payment_date[:zzF_Status] = "Approved"
			@payment_date[:zzPP_Authorization_Code] = @authorizationCode
			@payment_date[:zzPP_Response_Message] = @responseMessage

		elsif @responseKind == "Declined"
			@payment_date[:zzF_Status] = "Declined"
			@payment_date[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "Error"
			@payment_date[:zzF_Status] = "Error"
			@payment_date[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "HeldforReview"
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
