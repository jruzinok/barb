require 'csv'

def batch_tokenize_csv_customer_data
	load_csv_customer_files

	# This is used to mark the record's Date Processed.
	@today = Time.new

	# This outputs the batch id. It's used to display acts as the header or beginning of the process
	puts "\n\n\n\n\n"
	puts "----------------------------------------"
	puts "[CSV] #{@src_dir}"
	puts "[CUSTOMER TOKINIZATION PROCESS]"
	puts "[BATCH] #{@batch}"
	puts "[TIMESTAMP] #{Time.now}"
	puts "----------------------------------------"

	#create a new file
	csv_out = File.open(@dst_dir, 'wb')

	#read from existing file
	CSV.foreach(@src_dir, :headers => true) do |row|
		@cvsRow = row

		@step1 = load_csv_customer_data
		@step2 = create_customer_token_by_csv
		@step3 = log_result_to_console_for_batch_csv_tokenization

		# This prevents the record from being updated if a token wasn't created/attempted.
		if @flag_update_csv == true
			row[3] = @customer_token
		end

		@step5 = clear_response
		@step6 = clear_batch_tokenization_variables

		#Lastly,  write back the edited , regexed data ..etc to an out file.
		csv_out << row

	end

	# close the file 
	csv_out.close

end

def load_csv_customer_files
	@src_dir = "Customer_#{@batch}.csv"
	@dst_dir = "Customer_#{@batch}_Output.csv"	

	puts " Reading data from  : #{@src_dir}"
	puts " Writing data to    : #{@dst_dir}"
end

def load_csv_customer_data
	@customer = @cvsRow[0]
	@serial = @cvsRow[0]
	@namefirst = @cvsRow[1]
	@namelast = @cvsRow[2]
	@namefull = "#{@namefirst} #{@namelast}"
	@customer_token = @cvsRow[3]

	check_customer_token
end

def create_customer_token_by_csv
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

		@flag_update_csv = true
	else
		@flag_update_csv = false
	end
end

def batch_tokenize_csv_credit_card_data
	load_csv_credit_card_files

	# This is used to mark the record's Date Processed.
	@today = Time.new

	# This outputs the batch id. It's used to display acts as the header or beginning of the process
	puts "\n\n\n\n\n"
	puts "----------------------------------------"
	puts "[CSV] #{@src_dir}"
	puts "[CREDIT CARD TOKINIZATION PROCESS]"
	puts "[BATCH] #{@batch}"
	puts "[TIMESTAMP] #{Time.now}"
	puts "----------------------------------------"

		#create a new file
	csv_out = File.open(@dst_dir, 'wb')

	#read from existing file
	CSV.foreach(@src_dir, :headers => true) do |row|
		@cvsRow = row

		@step1 = load_csv_credit_card_data
		@step2 = create_payment_token_by_csv
		@step3 = log_result_to_console_for_batch_csv_tokenization

		# This prevents the record from being updated if a token wasn't created/attempted.
		if @flag_update_csv == true
			row[7] = @payment_token
		end

		@step5 = clear_response
		@step6 = clear_batch_tokenization_variables

		#Lastly,  write back the edited , regexed data ..etc to an out file.
		csv_out << row

	end

	# close the file 
	csv_out.close
end

def load_csv_credit_card_files
	@src_dir = "Credit_Card_#{@batch}.csv"
	@dst_dir = "Credit_Card_#{@batch}_Output.csv"	

	puts " Reading data from  : #{@src_dir}"
	puts " Writing data to    : #{@dst_dir}"
end

def load_csv_credit_card_data
	@serial = @cvsRow[0]
	@namefirst = @cvsRow[1]
	@namelast = @cvsRow[2]
	@cardnumber = @cvsRow[3]
	@carddate = @cvsRow[4]
	@cardcvv = @cvsRow[5]
	@customer_token = @cvsRow[6]
	@payment_token = @cvsRow[7]

	check_customer_token
	check_payment_token
end

def create_payment_token_by_csv
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

		@flag_update_csv = true

	else
		@flag_update_csv = false
	end
end

def log_result_to_console_for_batch_csv_tokenization
	puts "R-#{@responseKind},S-#{@serial},CT-#{@customer_token},PT-#{@payment_token},RC-#{@responseCode},M-#{@statusMessage},E-#{@responseError}"
end
