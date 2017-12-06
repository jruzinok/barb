def create_payment_method_payment_token
	create_directory_customer_token

	if @has_customer_token == true
		find_payment_method

		if @payment_method_found == true && @has_payment_token == false
			@skip_find_payment_method = true # This prevents the find routine from hitting the database again (to speed the process up and make it less db intensive).
			create_payment_token
			@save_payment_method = "Update" # Update the PM record that already exists in the database.
			save_payment_method
			create_payment_processor_log

		elsif @payment_method_found == true && @has_payment_token == true
			@status_code = 220
			@status_message = "[ERROR] PaymentTokenAlreadyExists"
			log_result_to_console
		end
	end

	set_response
end

def delete_payment_token
	unless @skip_find_directory == true
		find_directory
	end

	unless @skip_find_payment_method == true
		find_payment_method
	end

	if @directory_found == true && @has_customer_token == true && @payment_method_found == true && @has_payment_token == true
		request = DeleteCustomerPaymentProfileRequest.new
		request.customerProfileId = @customer_token
		request.customerPaymentProfileId = @payment_token

		@response = transaction.delete_customer_payment_profile(request)

		# The transaction has a response.
		if transaction_ok
			@status_code = 200
			@status_message = "[OK] PaymentTokenDeleted"
			log_result_to_console
		else
			@status_code = 210
			@status_message = "[ERROR] PaymentTokenNotDeleted"
			log_result_to_console
		end

		update_payment_method_after_payment_token_is_deleted
		create_payment_processor_log
		set_response
	end
end

def find_payment_method
	if @database == "BC" || @database == "CS"
		@payment_method = DATAPaymentMethod.find(:__kP_PaymentMethod => @payment_method_id)
	elsif @database == "PTD"
		@payment_method = PTDPaymentMethod.find(:__kP_PaymentMethod => @payment_method_id)
	end

	if @payment_method[0] != nil
		@payment_method_found = true
		@payment_method = @payment_method[0] # Load the record from the first position of the array.
		load_payment_method
	else
		@payment_method_found = false
		@status_code = 300
		@status_message = "[ERROR] PaymentMethodRecordNotFound"
		set_response
		log_result_to_console
	end
end

def load_payment_method_by_batch
	@card_name_first = @payment_method["Name_First"]
	@card_name_last = @payment_method["Name_Last"]
	@customer_token = @payment_method["T55_DIRECTORY::Token_Profile_ID"]
	@payment_token = @payment_method["Token_Payment_ID"]
	@card_number = @payment_method["CreditCard_Number"]
	@card_mmyy = @payment_method["MMYY"]
	@card_cvv = @payment_method["CVV"]
	@address = @payment_method["Address_Address"]
	@city = @payment_method["Address_City"]
	@state = @payment_method["Address_State"]
	@zip = @payment_method["Address_Zip"]

	check_customer_token
	check_payment_token
end

def load_payment_method
	@card_name_first = @payment_method["Name_First"]
	@card_name_last = @payment_method["Name_Last"]
	@merchant_payment_method = @payment_method["zzF_Merchant"] # Not currently being used.
	@payment_token = @payment_method["Token_Payment_ID"]
	@address = @payment_method["Address_Address"]
	@city = @payment_method["Address_City"]
	@state = @payment_method["Address_State"]
	@zip = @payment_method["Address_Zip"]

	check_payment_token
end

# @save_payment_method = "Create"

def save_payment_method
	if @save_payment_method == "Create"
		create_payment_method
		update_payment_method
	elsif @save_payment_method == "Update"
		update_payment_method
	end
end

def create_payment_method
	if @target_database == "DATA"
		@payment_method = DATAPaymentMethod.new
	elsif @target_database == "PTD"
		@payment_method = PTDPaymentMethod.new
	end

	@payment_method[:_kF_Directory] = @directory_id
	@payment_method[:Name_First] = @name_first
	@payment_method[:Name_Last] = @name_last
	@payment_method[:CreditCard] = @card_number
	@payment_method[:MMYY] = @card_mmyy
	@payment_method[:CVV] = @card_cvv

	# I am purposely NOT saving the record here. Instead, it'll be saved in the update_payment_token method.
end

def update_payment_method
	if @result == "OK"
		@payment_method[:Token_Payment_ID] = @payment_token
		@payment_method[:zzF_Merchant] = @merchant
		@payment_method[:zzF_Status] = "Active"
		@payment_method[:zzF_Type] = "Token"
	else
		@payment_method[:zzPP_Response] = @response
		@payment_method[:zzPP_Response_Code] = @response_code
		@payment_method[:zzPP_Response_Error] = @response_error
		@payment_method[:zzF_Status] = "Inactive"
		@payment_method[:zzF_Type] = "Error"
	end

	@payment_method.save
end

def update_payment_method_after_payment_token_is_deleted
	if @result == "OK"
		@payment_method[:Token_Payment_ID] = ""
		@payment_method[:zzF_Status] = "Deleted"
		@payment_method[:zzF_Type] = "Token"
	else
		@payment_method[:zzPP_Response] = @response
		@payment_method[:zzPP_Response_Code] = @response_code
		@payment_method[:zzPP_Response_Error] = @response_error
		@payment_method[:zzF_Status] = "Inactive"
		@payment_method[:zzF_Type] = "Error"
	end

	@payment_method.save
end

def update_payment_token
	find_directory
	find_payment_method

	if @directory_found == true && @has_customer_token == true && @payment_method_found == true && @has_payment_token == true
		retrieve_payment_token

		if @payment_token_retrieved == true
			request = UpdateCustomerPaymentProfileRequest.new

			# Set the @card_mmyy = 'XXXX' and @card_cvv = nil if the user didn't enter any values.
			mask_card_date
			nil_card_cvv

			# The credit card number should not be updated per Ashley's decision. Hence the use of the @masked_card_number variable.
			creditcard = CreditCardType.new(@masked_card_number,@card_mmyy,@card_cvv)

			payment = PaymentType.new(creditcard)
			profile = CustomerPaymentProfileExType.new(nil,nil,payment,nil,nil)
			if @update_card_address == true
				profile.billTo = CustomerAddressType.new
				profile.billTo.firstName = @name_first
				profile.billTo.lastName = @name_last
				profile.billTo.address = @address
				profile.billTo.city = @city
				profile.billTo.state = @state
				profile.billTo.zip = @zip
			end
			request.paymentProfile = profile
			request.customerProfileId = @customer_token
			profile.customerPaymentProfileId = @payment_token

			# PASS the transaction request and CAPTURE the transaction response.
			@response = transaction.update_customer_payment_profile(request)

			if transaction_ok
				@payment_token_updated = true

				@status_code = 200
				@status_message = "[OK] PaymentTokenUpdated"
				log_result_to_console
			else
				@payment_token_updated = false
				@status_code = 210
				@status_message = "[ERROR] PaymentTokenNotUpdated"
				log_result_to_console
			end

			create_payment_processor_log
		end
				
	else
		@status_code = 230
		@status_message = "[ERROR] PaymentTokenCouldNotBeUpdated"
		log_result_to_console
	end

	set_response
	clear_response
end

def retrieve_payment_token
	request = GetCustomerPaymentProfileRequest.new
	request.customerProfileId = @customer_token
	request.customerPaymentProfileId = @payment_token

	@response = transaction.get_customer_payment_profile(request)

	if transaction_ok
		@payment_token_retrieved = true
		@masked_card_number = @response.paymentProfile.payment.creditCard.cardNumber
	else
		@payment_token_retrieved = false
		@status_code = 240
		@status_message = "[ERROR] PaymentTokenCouldNotBeRetrieved"
		log_result_to_console
	end
end

def batch_tokenize_payment_methods
	find_payment_methods_to_tokenize_by_batch

	# This is used to mark the record's Date Processed.
	@today = Time.new

	# This outputs the batch id. It's used to display acts as the header or beginning of the process
	puts "\n\n\n\n\n"
	puts "----------------------------------------"
	puts "[DATABASE] #{@database}"
	puts "[PAYMENT TOKINIZATION PROCESS]"
	puts "[BATCH] #{@batch}"
	puts "[TIMESTAMP] #{Time.now}"
	puts "----------------------------------------"

	@payment_methods.each do |pm|
		@payment_method = pm
		# These "steps" are for clarity sake.
		# Later, these objects could be saved somewhere to log the steps of each batch when it's run.
		@step1 = load_payment_method_by_batch
		@step2 = create_payment_token_by_batch
		@step3 = log_result_to_console_for_batch_tokenization

		# This prevents the record from being updated if a token wasn't created/attempted.
		if @flag_update_payment_method == true
			@step4 = update_payment_method
		end

		@step5 = clear_response
		@step6 = clear_batch_tokenization_variables
	end

end

def find_payment_methods_to_tokenize_by_batch
	if @database == "BC"
		@payment_methods = DATAPaymentMethod.find(:zzF_Batch => @batch)
	elsif @database == "PTD"
		@payment_methods = PTDPaymentMethod.find(:zzF_Batch => @batch)
	end
end

def create_payment_token_by_batch
	if @has_customer_token == true && @has_payment_token == false
		create_payment_token
		@flag_update_payment_method = true
	else
		@flag_update_payment_method = false
	end
end
