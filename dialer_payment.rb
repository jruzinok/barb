def save_dailerpayment
	if @responseKind == "OK"
		@dailerpayment = DialerPayment.new

		@dailerpayment[:_kF_DialerLead] = @lead_id
		@dailerpayment[:_kF_Guest] = @guest_id

		@dailerpayment[:Token_Profile_ID] = @customer_token
		@dailerpayment[:Token_Payment_ID] = @payment_token

		@dailerpayment[:Date] = @date
		@dailerpayment[:Amount] = @amount
		
		@dailerpayment[:Name_First] = @namefirst
		@dailerpayment[:Name_Last] = @namelast
		@dailerpayment[:CreditCard_Number] = @cardnumber
		@dailerpayment[:MMYY] = @carddate
		@dailerpayment[:CVV] = @cardcvv
		@dailerpayment[:Address_Address] = @address
		@dailerpayment[:Address_City] = @city
		@dailerpayment[:Address_State] = @state
		@dailerpayment[:Address_Zip] = @zip
	else
		@dailerpayment[:zzPP_Response] = @theResponse
		@dailerpayment[:zzPP_Response_Code] = @responseCode
		@dailerpayment[:zzPP_Response_Error] = @responseError
	end

	@dailerpayment.save
end
