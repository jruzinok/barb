require 'bigdecimal'

# def show
# 	@record = PaymentDate.find params[:id]
# end

def find_by_batch
	if @database == "PTD"
		@paymentdates = PTDPaymentDate.find(:_kF_PaymentBatch => @batch)
	elsif @database == "BC"
		@paymentdates = BCPaymentDate.find(:_kF_PaymentBatch => @batch)
	end
end

def find_by_status_and_date
	if @database == "PTD"
		@paymentdates = PTDPaymentDate.find(:zzF_Status => @status, :Date => @date)
	elsif @database == "BC"
		@paymentdates = BCPaymentDate.find(:zzF_Status => @status, :Date => @date)
	end
end

def process
	find_by_batch

	# This outputs the batch id. It's used to display acts as the header or beginning of the process
	puts "\n\n\n\n\n"
	puts "\n----------------------------------------"
	puts "\n[DATABASE] #{@database}"
	puts "\n[BATCH] #{@batch})"
	puts "\n[TIMESTAMP] #{Time.now.utc.iso8601}"
	puts "\n----------------------------------------"

	@paymentdates.each do |pd|
		@paymentdate = pd
		# These "steps" are for clarity sake.
		# Later, these objects could be saved somewhere to log the steps of each batch when it's run.
		@step1 = load
		@step2 = charge_credit_card()
		@step3 = report
		@step4 = update
	end

	# This final step calls the Payment Processor Tool script in the Payment Processor application file.
	@step5 = BCPaymentDate.find({:_kF_PaymentBatch => @batch}, :post_script => ["PaymentProcessorCallBack", "#{@batch}\nInitiate from Ruby"])
end

def load
	@serial = @paymentdate["_Serial"].to_s
	@namefirst = @paymentdate["T54_Link | DIRECTORY ~ contestant::Name_First"]
	@namelast = @paymentdate["T54_Link | DIRECTORY ~ contestant::Name_Last"]

	# Address values.
	@address = @paymentdate["T54_PaymentMethod | CONTACTINFO::Add_Address1"]
	@city = @paymentdate["T54_PaymentMethod | CONTACTINFO::Add_City"]
	@state = @paymentdate["T54_PaymentMethod | CONTACTINFO::Add_State"]
	@zip = @paymentdate["T54_PaymentMethod | CONTACTINFO::Add_Zip"]

	# Credit Card values.
	@cardnumber = @paymentdate["T54_PAYMENTMETHOD::CreditCard_Number"]
	@carddate = @paymentdate["T54_PAYMENTMETHOD::MMYY"]
	@cardcvv = @paymentdate["T54_PAYMENTMETHOD::CVV"]

	# Transaction details.
	@amount = @paymentdate["Amount"].to_f
	@bc = @paymentdate["T54_LINK::zzC_BC_Location_ABBR"]
end

def report
	if @responseKind == "Approved"
		puts "[#{@responseKind}] CardNumber: #{@cardnumber} Authorization: #{@authorizationCode})"
	else
		puts "[#{@responseKind}] CardNumber: #{@cardnumber} Error: #{@responseError})"
	end

	puts "RESPONSECODE: #{@responseCode}"
	puts "RESPONSEMESSAGE: #{@responseMessage}"
	puts "RESPONSEERROR: #{@responseError}"
	puts "\n----------------------------------------"
end

def update
		# SAVE the response values for all transactions.

	# Record the transaction results for each processed payment.
	if @resultCode == "OK"
		@paymentdate[:zzPP_Transaction] = @transactionID

		@paymentdate[:zzPP_Response] = @response
		@paymentdate[:zzPP_Response_AVS_Code] = @avsCode
		@paymentdate[:zzPP_Response_CVV_Code] = @cvvCode

		@paymentdate[:zzPP_Response_Code] = @responseCode

		if @responseKind == "Approved"
			@paymentdate[:zzF_Status] = "Approved"
			@paymentdate[:zzPP_Authorization_Code] = @authorizationCode
			@paymentdate[:zzPP_Response_Message] = @responseMessage

		elsif @responseKind == "Declined"
			@paymentdate[:zzF_Status] = "Declined"
			@paymentdate[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "Error"
			@paymentdate[:zzF_Status] = "Error"
			@paymentdate[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "HeldforReview"
			@paymentdate[:zzF_Status] = "HeldForReview"
			@paymentdate[:zzPP_Response_Error] = @responseError
		end

	# These payments were NOT processes.
	else
		if @responseKind == "TransactionError"
			@paymentdate[:zzF_Status] = "Error"
			@paymentdate[:zzPP_Transaction] = @transactionID

			@paymentdate[:zzPP_Response] = @response
			@paymentdate[:zzPP_Response_Code] = @responseCode
			@paymentdate[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "TransactionFailure"
			@paymentdate[:zzPP_Response_Error] = @responseError
		end
	end

	@paymentdate.save
end