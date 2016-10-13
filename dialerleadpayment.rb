def process_create_dialier_payment_request
	parse_create_dialer_payment_post

	if @requestType == "Charge"
		create_dialer_tokens
		process_dialer_payment
	elsif @requestType == "Schedule"
		create_dialer_tokens
	end
end

def parse_create_dialer_payment_post
	@database = params[:database]
	@directory_id = params[:directory_id]
	@payment_method_id = params[:payment_method_id]

	# Grab the credit card values from the POST object.
	@cardnumber = params[:CreditCard]
	@carddate = params[:MMYY]
	@cardcvv = params[:CVV]

end

def create_dailerleadpayment
	if @responseKind == "OK"
		@dailerleadpayment = DialerLeadPayment.new

		if @recordtype == "DialerLead"
			@dailerleadpayment[:_kF_DialerLead] = @lead_id
		elsif @recordtype == "DialerGuest"
			@dailerleadpayment[:_kF_Guest] = @guest_id
		end

		@dailerleadpayment[:Token_Profile_ID] = @customer_token
		@dailerleadpayment[:Token_Payment_ID] = @payment_token

		@dailerleadpayment[:Date] = @date
		@dailerleadpayment[:Amount] = @amount
		
		@dailerleadpayment[:Name_First] = @namefirst
		@dailerleadpayment[:Name_Last] = @namelast
		@dailerleadpayment[:CreditCard_Number] = @cardnumber
		@dailerleadpayment[:MMYY] = @carddate
		@dailerleadpayment[:CVV] = @cardcvv
		@dailerleadpayment[:Address_Address] = @address
		@dailerleadpayment[:Address_City] = @city
		@dailerleadpayment[:Address_State] = @state
		@dailerleadpayment[:Address_Zip] = @zip
	else
		@dailerleadpayment[:zzPP_Response] = @theResponse
		@dailerleadpayment[:zzPP_Response_Code] = @responseCode
		@dailerleadpayment[:zzPP_Response_Error] = @responseError
	end

	@dailerleadpayment.save
end
