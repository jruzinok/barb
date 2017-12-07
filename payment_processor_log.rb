def create_payment_processor_log
	# Record the transaction results for each processed payment.
	@payment_processor_log = DATAPaymentProcessorLog.new

	# Authorize Details
	@payment_processor_log[:zzPP_Transaction] = @transaction_id
	@payment_processor_log[:zzPP_Response] = @authorize_response
	@payment_processor_log[:zzPP_Response_AVS_Code] = @avs_code
	@payment_processor_log[:zzPP_Response_CVV_Code] = @cvv_code
	@payment_processor_log[:zzPP_Response_Code] = @authorize_response_code

	# Keys
	@payment_processor_log[:_kF_PaymentBatch] = @batch
	@payment_processor_log[:_kF_Directory] = @directory_id
	@payment_processor_log[:_kF_Statement] = @statement_id
	@payment_processor_log[:_kF_DialerLead] = @lead_id
	@payment_processor_log[:_kF_Guest] = @guest_id
	@payment_processor_log[:_kF_PaymentMethod] = @payment_method_id
	@payment_processor_log[:_kF_PaymentDate] = @payment_date_id

	# Payments
	@payment_processor_log[:Amount] = @amount
	@payment_processor_log[:Date_Processed] = @date

	# Name
	@payment_processor_log[:Name_First] = @name_first
	@payment_processor_log[:Name_Last] = @name_last

	# Credit Card
	@payment_processor_log[:CreditCard_Number] = @card_number
	@payment_processor_log[:CreditCard_MMYY] = @card_mmyy
	@payment_processor_log[:CreditCard_CVV] = @card_cvv

	# Tokens
	@payment_processor_log[:Token_Profile_ID] = @customer_token
	@payment_processor_log[:Token_Payment_ID] = @payment_token

	# RECORD which database, process and batch created this record.
	@payment_processor_log[:Log_Database] = @database
	@payment_processor_log[:Log_Process] = @process
	@payment_processor_log[:Log_Process_Type] = @processType

	if @processType == "Token"

		@payment_processor_log[:zzPP_Response_Message] = @status_message
		@payment_processor_log[:zzPP_Response_Error] = @authorize_response_error

		# Only applicable to the update_payment_token method WHEN the user selected to update the billing address (avs).
		if @update_card_address == true
			@payment_processor_log[:zzF_Update_Address] = "Yes"
			@payment_processor_log[:Address_Address] = @address
			@payment_processor_log[:Address_City] = @city
			@payment_processor_log[:Address_State] = @state
			@payment_processor_log[:Address_Zip] = @zip
		end

	elsif @processType == "Payment"

		if @result == "OK"

			if @authorize_response_kind == "Approved"
				@payment_processor_log[:zzF_Status] = "Approved"
				@payment_processor_log[:zzPP_Authorization_Code] = @authorization_code
				@payment_processor_log[:zzPP_Response_Message]  = @authorize_response_message

			elsif @authorize_response_kind == "Declined"
				@payment_processor_log[:zzF_Status] = "Declined"
				@payment_processor_log[:zzPP_Response_Error] = @authorize_response_error

			elsif @authorize_response_kind == "Error"
				@payment_processor_log[:zzF_Status] = "Error"
				@payment_processor_log[:zzPP_Response_Error] = @authorize_response_error

			elsif @authorize_response_kind == "HeldforReview"
				@payment_processor_log[:zzF_Status] = "HeldForReview"
				@payment_processor_log[:zzPP_Response_Error] = @authorize_response_error
			end

		# These payments were NOT processes.
		elsif @result == "ERROR"

			if @authorize_response_kind == "TransactionError"
				@payment_processor_log[:zzF_Status] = "TransactionError"
				@payment_processor_log[:zzPP_Transaction] = @transaction_id

				@payment_processor_log[:zzPP_Response] = @authorize_response
				@payment_processor_log[:zzPP_Response_Code] = @authorize_response_code
				@payment_processor_log[:zzPP_Response_Error] = @authorize_response_error

			elsif @authorize_response_kind == "TokenError"
				@payment_processor_log[:zzF_Status] = "TokenError"
				@payment_processor_log[:zzPP_Response] = @authorize_response
				@payment_processor_log[:zzPP_Response_Code] = @authorize_response_code
				@payment_processor_log[:zzPP_Response_Error] = @authorize_response_error

			elsif @authorize_response_kind == "TransactionFailure"
				@payment_processor_log[:zzF_Status] = "TransactionFailure"
				@payment_processor_log[:zzPP_Response_Error] = @authorize_response_error
			end
		end
	end

	@payment_processor_log.save
end