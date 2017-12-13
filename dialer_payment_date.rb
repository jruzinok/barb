def save_processed_dailer_payment_date
	# Record the transaction results for each processed payment.
	@dailer_payment = DIALERPaymentDate.new
	
	@dailer_payment[:_kF_DialerLead] = @lead_id
	@dailer_payment[:_kF_Guest] = @guest_id
	@dailer_payment[:_kF_PaymentMethod] = @payment_method_id

	@dailer_payment[:Date] = @date
	@dailer_payment[:Amount] = @amount

	@dailer_payment[:zzF_Status] = @authorize_response_kind
	@dailer_payment[:zzPP_Transaction] = @transaction_id
	@dailer_payment[:zzPP_Response] = @authorize_response
	@dailer_payment[:zzPP_Response_Code] = @authorize_response_code
	@dailer_payment[:zzPP_Response_AVS_Code] = @avs_code
	@dailer_payment[:zzPP_Response_CVV_Code] = @cvv_code

	if @authorize_response_kind == "Approved"
		@dailer_payment[:zzPP_Authorization_Code] = @authorization_code
		@dailer_payment[:zzPP_Response_Message] = @authorize_response_message
	else
		@dailer_payment[:zzPP_Response_Error] = @authorize_response_message
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
