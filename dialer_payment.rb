def save_dailer_payment
	if @responseKind == "OK"
		@dailer_payment = DialerPayment.new

		@dailer_payment[:_kF_DialerLead] = @lead_id
		@dailer_payment[:_kF_Guest] = @guest_id
		@dailer_payment[:_kF_PaymentMethod] = @payment_method_id

		@dailer_payment[:Date] = @date
		@dailer_payment[:Amount] = @amount
		@dailer_payment[:zzPP_Response_Code] = @responseCode
	else
		@dailer_payment[:zzPP_Response] = @theResponse
		@dailer_payment[:zzPP_Response_Code] = @responseCode
		@dailer_payment[:zzPP_Response_Error] = @responseError
	end

	@dailer_payment.save
end
