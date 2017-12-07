def save_processed_dailer_payment_date
	# Record the transaction results for each processed payment.
	@dailer_payment = DIALERPaymentDate.new
	
	@dailer_payment[:_kF_DialerLead] = @lead_id
	@dailer_payment[:_kF_Guest] = @guest_id
	@dailer_payment[:_kF_PaymentMethod] = @payment_method_id

	@dailer_payment[:Date] = @date
	@dailer_payment[:Amount] = @amount
	@dailer_payment[:zzPP_Transaction] = @transaction_id

	@dailer_payment[:zzPP_Response] = @authorize_response
	@dailer_payment[:zzPP_Response_AVS_Code] = @avs_code
	@dailer_payment[:zzPP_Response_CVV_Code] = @cvv_code

	@dailer_payment[:zzPP_Response_Code] = @authorize_response_code

	if @result == "OK"
	
		if @authorize_response_kind == "Approved"
			@dailer_payment[:zzF_Status] = "Approved"
			@dailer_payment[:zzPP_Authorization_Code] = @authorization_code
			@dailer_payment[:zzPP_Response_Message] = @authorize_response_message

		elsif @authorize_response_kind == "Declined"
			@dailer_payment[:zzF_Status] = "Declined"
			@dailer_payment[:zzPP_Response_Error] = @authorize_response_error

		elsif @authorize_response_kind == "Error"
			@dailer_payment[:zzF_Status] = "Error"
			@dailer_payment[:zzPP_Response_Error] = @authorize_response_error

		elsif @authorize_response_kind == "HeldforReview"
			@dailer_payment[:zzF_Status] = "HeldForReview"
			@dailer_payment[:zzPP_Response_Error] = @authorize_response_error
		end

	# These payments were NOT processes.
	elsif @result == "ERROR"

		if @authorize_response_kind == "TransactionError"
			@dailer_payment[:zzF_Status] = "TransactionError"
			@dailer_payment[:zzPP_Transaction] = @transaction_id

			@dailer_payment[:zzPP_Response] = @authorize_response
			@dailer_payment[:zzPP_Response_Code] = @authorize_response_code
			@dailer_payment[:zzPP_Response_Error] = @authorize_response_error

		elsif @authorize_response_kind == "TokenError"
			@dailer_payment[:zzF_Status] = "TokenError"
			@dailer_payment[:zzPP_Response] = @authorize_response
			@dailer_payment[:zzPP_Response_Code] = @authorize_response_code
			@dailer_payment[:zzPP_Response_Error] = @authorize_response_error

		elsif @authorize_response_kind == "TransactionFailure"
			@dailer_payment[:zzF_Status] = "TransactionFailure"
			@dailer_payment[:zzPP_Response_Error] = @authorize_response_error
		end
	end

	@dailer_payment.save
end

def save_scheduled_dailer_payment_date
		@dailer_payment = DIALERPaymentDate.new

		@dailer_payment[:_kF_DialerLead] = @lead_id
		@dailer_payment[:_kF_Guest] = @guest_id
		@dailer_payment[:_kF_PaymentMethod] = @payment_method_id

		@dailer_payment[:Date] = @date
		@dailer_payment[:Amount] = @amount
		@dailer_payment[:zzF_Status] = "Pending"

		@dailer_payment.save
end
