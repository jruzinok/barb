def process_create_dialier_payment_request
	parse_create_dialer_payment_post

	if @requestType == "Charge"
		create_dialer_tokens
		process_dialer_payment
	elsif @requestType == "Schedule"
		create_dialer_tokens
	end

	# Save the results into FileMaker.
	save_dailerpayment
end

def create_dialer_tokens
	if @recordtype = "DialerLead"

	elsif @recordtype = "DialerGuest"
		
	end
end

def parse_create_dialer_payment_post
	@lead_id = params[:lead_id]
	@guest_id = params[:guest_id]
	@requestType = params[:requestType]

	# Grab the values from the POST object.
	@date = @params[:Date]
	@amount = @params[:Amount]
	
	@namefirst = params[:Name_First]
	@namelast = params[:Name_Last]
	@cardnumber = params[:CreditCard]
	@carddate = params[:MMYY]
	@cardcvv = params[:CVV]
	@address = params[:Address_Address]
	@city = params[:Address_City]
	@state = params[:Address_State]
	@zip = params[:Address_Zip]
end