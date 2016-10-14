def save_processed_dailer_payment
	# Record the transaction results for each processed payment.
	@dailer_payment = DialerPayment.new

	if @resultCode == "OK"
		@dailer_payment[:_kF_DialerLead] = @lead_id
		@dailer_payment[:_kF_Guest] = @guest_id
		@dailer_payment[:_kF_PaymentMethod] = @payment_method_id

		@dailer_payment[:Date] = @date
		@dailer_payment[:Amount] = @amount
		@dailer_payment[:zzPP_Transaction] = @transactionID

		@dailer_payment[:zzPP_Response] = @theResponse
		@dailer_payment[:zzPP_Response_AVS_Code] = @avsCode
		@dailer_payment[:zzPP_Response_CVV_Code] = @cvvCode

		@dailer_payment[:zzPP_Response_Code] = @responseCode

		if @responseKind == "Approved"
			@dailer_payment[:zzF_Status] = "Approved"
			@dailer_payment[:zzPP_Authorization_Code] = @authorizationCode
			@dailer_payment[:zzPP_Response_Message] = @responseMessage

		elsif @responseKind == "Declined"
			@dailer_payment[:zzF_Status] = "Declined"
			@dailer_payment[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "Error"
			@dailer_payment[:zzF_Status] = "Error"
			@dailer_payment[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "HeldforReview"
			@dailer_payment[:zzF_Status] = "HeldForReview"
			@dailer_payment[:zzPP_Response_Error] = @responseError
		end

	# These payments were NOT processes.
	else
		if @responseKind == "TransactionError"
			@dailer_payment[:zzF_Status] = "Error"
			@dailer_payment[:zzPP_Transaction] = @transactionID

			@dailer_payment[:zzPP_Response] = @theResponse
			@dailer_payment[:zzPP_Response_Code] = @responseCode
			@dailer_payment[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "TokenError"
			@dailer_payment[:zzPP_Response] = @theResponse
			@dailer_payment[:zzPP_Response_Code] = @responseCode
			@dailer_payment[:zzPP_Response_Error] = @responseError

		elsif @responseKind == "TransactionFailure"
			@dailer_payment[:zzPP_Response_Error] = @responseError
		end
	end

	@dailer_payment.save
end

def save_scheduled_dailer_payment
		@dailer_payment = DialerPayment.new

		@dailer_payment[:_kF_DialerLead] = @lead_id
		@dailer_payment[:_kF_Guest] = @guest_id
		@dailer_payment[:_kF_PaymentMethod] = @payment_method_id

		@dailer_payment[:Date] = @date
		@dailer_payment[:Amount] = @amount
		@dailer_payment[:zzF_Status] = "Pending"

		@dailer_payment.save
end
