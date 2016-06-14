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
	@step5 = BCPaymentDate.find({:_kF_PaymentBatch => @batch}, :post_script => ["PaymentProcessorCallBack", "#{@batch}¶Initiate from Ruby"])
end

def load
	@serial = @paymentdate["_Serial"]
	rel = "T54_PaymentDate | PAYMENTMETHOD::"
	@cardname = @paymentdate["#{rel}zzC_Name_Full"]
	@cardnumber = @paymentdate["#{rel}CreditCard_Number"]
	@carddate = @paymentdate["#{rel}MMYY"]
	@cardcvv = @paymentdate["#{rel}CVV"]
	@amount = @paymentdate["Amount"].to_f
	@bc = @paymentdate["T54_LINK::zzC_BC_Location_ABBR"]
end

def report
	if @responseKind == "OK"
		puts "[Success] CardNumber: #{@cardnumber} Authorization: #{@authorizationCode})"
	elsif @responseKind == "Error"
		puts "[Error] CardNumber: #{@cardnumber} Error: #{@responseCode} #{@responseError} #{@responseMessage})"
	elsif @responseKind == "Failure"
		puts "[Failure] PaymentDate Serial: #{@serial} Error: #{@responseMessage})"
	end
end

def update
	if @responseKind == "OK"
		@paymentdate[:zzF_Status] = "Approved"
		@paymentdate[:zzPP_Transaction] = @transactionID
		@paymentdate[:zzPP_Authorization_Code] = @authorizationCode
	elsif @responseKind == "Error"
		@paymentdate[:zzF_Status] = "Declined"
		@paymentdate[:zzPP_Response_Code] = @responseCode
		@paymentdate[:zzPP_Response_Error] = @responseError
		@paymentdate[:zzPP_Response_Message] = @responseMessage
	elsif @responseKind == "Failure"
		@paymentdate[:zzPP_Response_Message] = @responseMessage
	end

	@paymentdate.save
end