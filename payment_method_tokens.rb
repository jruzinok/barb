def validate_multiple_tokens
	# This is used to mark when the PaymentMethod record was last validated.
	@today = Time.now
	@one_month_ago = one_month_ago(@today)

	# This outputs the batch id. It's used to display acts as the header or beginning of the process
	puts "\n\n\n\n\n"
	puts "----------------------------------------"
	puts "[DATABASE] #{@database}"
	puts "[VALIDATE TOKENS]"
	puts "[BATCH] #{@batch}"
	puts "[TIMESTAMP] #{Time.now}"
	puts "----------------------------------------"

	find_payment_methods_by_batch

	@payment_methods.each do |pm|
		@payment_method = pm

		@step1 = load_payment_method
		@step2 = capture_related_directory_id
		@step3 = find_directory
		@step3b = check_directory_and_payment_method_merchants
		@step4 = validate_tokens
		@step5 = log_token_validation_result_to_console
		@step5b = retrieve_payment_token
		@step5c = update_payment_method_issuer_number
		@step6 = save_payment_method_token_validation_result
		@step7 = clear_response
	end

end

# This method is used to determine the date one month ago.
# This value is used to exclude any PaymentMethod records that have been validated within a month.
def one_month_ago (date)
	one_month_in_seconds = 2629746
	one_month_ago = date - one_month_in_seconds
	one_month_ago.strftime("%m/%d/%Y")
end

def find_payment_methods_by_batch
	if @database == "DATA" || @database == "BC" || @database == "CS"
		@payment_methods = DATAPaymentMethod.find([{:zzF_Batch => @batch}, {:Date_Validated => ">#{@one_month_ago}", :omit => true}])
	elsif @database == "PTD"
		@payment_methods = PTDPaymentMethod.find([{:zzF_Batch => @batch}, {:Date_Validated => ">#{@one_month_ago}", :omit => true}])
	end
	
end

def capture_related_directory_id
	@directory_id = @payment_method["_kF_Directory"]
end

# This is dependant on the retrieve_payment_token method.
def update_payment_method_issuer_number
	if @result == "OK"
		@payment_method[:CreditCard_Issuer_Number] = @card_issuer_number
	end
end

def save_payment_method_token_validation_result
	if @valid_tokens == true
		@payment_method[:zzF_Validated] = "Valid"
		@payment_method[:zzF_Status] = "Active"
		@payment_method[:zzF_Type] = "Token"
	else
		@payment_method[:zzPP_Response] = @authorize_response
		@payment_method[:zzPP_Response_Code] = @authorize_response_code
		@payment_method[:zzPP_Response_Error] = @authorize_response_message.sub "(TESTMODE) ", ""
		@payment_method[:zzF_Validated] = "NotValid"
		@payment_method[:zzF_Status] = "Inactive"
		@payment_method[:zzF_Type] = "Error"
	end

	@payment_method[:Date_Validated] = @today
	@payment_method.save
end

def log_token_validation_result_to_console
	puts "\n"
	puts "----------------------------------------"
	puts "[DIRECTORY] #{@directory_id}"
	puts "[PAYMENTMETHOD] #{@payment_method_id}"
	puts "[CUSTOMERTOKEN] #{@customer_token}"
	puts "[PAYMENTTOKEN] #{@payment_token}"
	puts "\n"
	puts "[VALID] #{@valid_tokens}"
	puts "[CODE] #{@authorize_response_code}"
	puts "[ERROR] #{@authorize_response_message}"
	puts "\n"
	puts "[TIMESTAMP] #{Time.now}"
	puts "----------------------------------------"
end