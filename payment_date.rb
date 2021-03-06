require 'bigdecimal'

def process_payment_dates

	# This is used to mark the record's Date Processed.
	# It's also used to determine the GL Code for Current Student Payment Dates.
	@today = Time.new

	# This outputs the batch id. It's used to display acts as the header or beginning of the process
	puts "\n\n\n\n\n"
	puts "----------------------------------------"
	puts "[DATABASE] #{@database}"
	puts "[BATCH] #{@batch}"
	puts "[TIMESTAMP] #{Time.now}"
	puts "----------------------------------------"

	find_by_batch
	set_gl_codes

	@payment_dates.each do |pd|
		@payment_date = pd
		load_which_payment_date
		process_or_skip
		log_result_to_console
		update_payment_date
		create_payment_processor_log
		clear_response
		clear_payment_date_variables
	end

	# This final step calls a script in either the Data File or PTD17 which in turn calls a Payment Processor Tool script in the Payment Processor application file.
	if @database == "PTD"
		fm = PTDPaymentDate.find({:_kF_PaymentBatch => @batch}, :post_script => ["PaymentProcessorCallBack", "#{@batch}\nInitiate from Ruby\n[PTD]"])
	elsif @database == "BC"
		fm = DATAPaymentDate.find({:_kF_PaymentBatch => @batch}, :post_script => ["PaymentProcessorCallBack", "#{@batch}\nInitiate from Ruby\n[BC]"])
	elsif @database == "CS"
		fm = DATAPaymentDate.find({:_kF_PaymentBatch => @batch}, :post_script => ["PaymentProcessorCallBack", "#{@batch}\nInitiate from Ruby\n[CS]"])
	elsif @database == "DL"
		fm = DIALERPaymentDate.find({:_kF_PaymentBatch => @batch}, :post_script => ["PaymentProcessorCallBack", "#{@batch}\nInitiate from Ruby\n[DL]"])
	end
end

def find_by_batch
	if @database == "PTD"
		@payment_dates = PTDPaymentDate.find(:_kF_PaymentBatch => @batch)
	elsif @database == "BC" || @database == "CS"
		@payment_dates = DATAPaymentDate.find(:_kF_PaymentBatch => @batch)
	elsif @database == "DL"
		@payment_dates = DIALERPaymentDate.find(:_kF_PaymentBatch => @batch)
	end
end

def find_payment_date
	if @database == "DATA" || @database == "BC" || @database == "CS"
		@payment_date = DATAPaymentDate.find(:__kP_PaymentDate => @payment_date_id)
	elsif @database == "PTD"
		@payment_date = PTDPaymentDate.find(:__kP_PaymentDate => @payment_date_id)
	end

	if @payment_date[0] != nil
		@payment_date_found = true
		@payment_date = @payment_date[0] # Load the record from the first position of the array.
		load_payment_date
	else
		@payment_date_found = false
		@status_code = 300
		@status_message = "[ERROR] PaymentDateRecordNotFound"
		set_response
		log_result_to_console
	end
end

def load_which_payment_date
	if @database == "PTD" || @database == "BC" || @database == "CS"
		load_payment_date
	elsif @database == "DL"
		load_dialer_payment_date
	end
end

def load_payment_date
	@payment_date_id = @payment_date["__kP_PaymentDate"]
	@serial = @payment_date["_Serial"].to_i
	@directory_id = @payment_date["_kF_Directory"]
	@payment_method_id = @payment_date["_kF_PaymentMethod"]

	@customer_token = @payment_date["T54_DIRECTORY::Token_Profile_ID"]
	@payment_token = @payment_date["T54_PAYMENTMETHOD::Token_Payment_ID"]

	# I am capturing both merchant flags to double check that they're associated to the same merchant account.
	@merchant_directory = @payment_date["T54_DIRECTORY::zzF_Merchant"]
	@merchant_payment_method = @payment_date["T54_PAYMENTMETHOD::zzF_Merchant"]

	# Credit Card values.
	@card_number = @payment_date["T54_PAYMENTMETHOD::CreditCard_Number"]
	@card_mmyy = @payment_date["T54_PAYMENTMETHOD::MMYY"]
	@card_cvv = @payment_date["T54_PAYMENTMETHOD::CVV"]

	@amount = @payment_date["Amount"].to_f

	if @database == "BC"
		@event_abbr = @payment_date["T54_EVENT::Name_Abbreviation"]
		@event_year = @payment_date["T54_EVENT::zzC_Year"]
		@gl_override_flag	= to_boolean(@payment_date["zzF_GL_Code_Override"])
		@gl_override_code	= @payment_date["GL_Code_Override"]
		set_gl_codes # The GL Code needs to be set for each PaymentDate record.
	elsif @database == "CS"
		@class_date = @payment_date["Date_Class"]
		@invoice = @payment_date["T54_DIRECTORY::Number_Invoice_GL"]
		set_gl_codes # The GL Code needs to be set for each PaymentDate record.
	end

	check_directory_and_payment_method_merchants
end

def load_dialer_payment_date
	# TBD: I need to update how the PHP Web Dialer app initiates this code to indicate which merchant to use. (12/12/2017)
	@payment_date_id = @payment_date["__kP_Payment"]
	@serial = @payment_date["_Serial"].to_i
	@lead_id = @payment_date["_kF_DialerLead"]
	@guest_id = @payment_date["_kF_Guest"]
	@payment_method_id = @payment_date["_kF_PaymentMethod"]

	@customer_token = @payment_date["DialerLeads::Token_Profile_ID"]
	@payment_token = @payment_date["PaymentMethod::Token_Payment_ID"]
	@amount = @payment_date["Amount"].to_f
end

def clear_payment_date_variables
	@directory_id = nil
	@lead_id = nil
	@guest_id = nil
	@payment_method_id = nil
	@payment_date_id = nil
	@serial = nil
	@name_first = nil
	@name_last = nil
	@name_full = nil
	@customer = nil
	@customer_token = nil
	@payment_token = nil
	@amount = nil
end

def update_payment_date

		if @result == "OK"

			# RECORD the Date Processed.
			if @database == "PTD" || @database == "BC" || @database == "CS"
				@payment_date[:Date_Processed] = @today
			end

			# SAVE the response values for all transactions.
			@payment_date[:zzF_Status] = @authorize_response_kind
			@payment_date[:zzPP_Transaction] = @transaction_id
			@payment_date[:zzPP_Response] = @authorize_response
			@payment_date[:zzPP_Response_Code] = @authorize_response_code
			@payment_date[:zzPP_Response_AVS_Code] = @avs_code
			@payment_date[:zzPP_Response_CVV_Code] = @cvv_code

			# These transaction WERE processed.
			if @authorize_response_kind == "Approved"
				@payment_date[:zzPP_Authorization_Code] = @authorization_code
				@payment_date[:zzPP_Response_Message] = @authorize_response_message
			else
				@payment_date[:zzPP_Response_Error] = @authorize_response_message
			end

		elsif @result == "ERROR"

			@payment_date[:zzF_Status] = @authorize_response_kind
			@payment_date[:zzPP_Transaction] = @transaction_id
			@payment_date[:zzPP_Response] = @authorize_response
			@payment_date[:zzPP_Response_Code] = @authorize_response_code
			@payment_date[:zzPP_Response_Error] = @authorize_response_message

		end

		# SAVE the changes to the database.
		@payment_date.save

end
