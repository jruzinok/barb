require 'bigdecimal'

# def show
# 	@record = PaymentDate.find params[:id]
# end

def find_by_batch (batch)
	@paymentdates = PaymentDate.find(:_kF_PaymentBatch => batch)
end

def find_by_status_and_date
	@paymentdates = PaymentDate.find(:zzF_Status => @status, :Date => @date)
end

def process (batch)
	# @date = "3/28/2016"
	# @status = "Scheduled"
	# find_by_status_and_date
	find_by_batch (batch)

	@paymentdates.each do |pd|
		@paymentdate = pd
		# These "steps" are for clarity sake.
		# Later, these objects could be saved somewhere to log the steps of each batch when it's run.
		@step1 = load
		@step2 = charge_credit_card()
		@step3 = report
		@step4 = update
	end
end

def load
	rel = "T54_PaymentDate | PAYMENTFORM::"
	@cardname = @paymentdate["#{rel}zzC_Name_Full"]
	@cardnumber = @paymentdate["#{rel}CreditCard_Number"]
	@carddate = @paymentdate["#{rel}MMYY"]
	@cardcvv = @paymentdate["#{rel}CVV"]
	@amount = @paymentdate[:Amount].to_f
end

def report
	if @responseKind == "OK"
		puts "[Success] CardNumber: #{@cardnumber} Authorization: #{@authorizationCode})"
	else
		puts "[Error] CardNumber: #{@cardnumber} Error: #{@responseCode} #{@responseError} #{@responseMessage})"
	end
end

def update
	if @responseKind == "OK"
		@paymentdate[:zzF_Status] = "Approved"
		@paymentdate[:zzPP_Transaction] = @transactionID
		@paymentdate[:zzPP_Authorization_Code] = @authorizationCode
	else
		@paymentdate[:zzF_Status] = "Declined"
		@paymentdate[:zzPP_Response_Code] = @responseCode
		@paymentdate[:zzPP_Response_Error] = @responseError
		@paymentdate[:zzPP_Response_Message] = @responseMessage
	end

	@paymentdate.save
end