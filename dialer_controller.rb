def process_create_dialer_payment_method_request
	parse_create_dialer_payment_method_post
	if @request_type == "Charge"
		create_dialer_tokens
		if @responseKind == "OK"
			process_dialer_payment
		end
	elsif @request_type == "Schedule"
		create_dialer_tokens
		if @responseKind == "OK"
			save_scheduled_dailer_payment
		end
	end

end

def process_create_dialer_payment_request
	parse_create_dialer_payment_method_post
	if @request_type == "Charge"
		load_dialer_tokens
		process_dialer_payment
	elsif @request_type == "Schedule"
		load_dialer_tokens
		save_scheduled_dailer_payment
	end

end

def parse_create_dialer_payment_method_post
	@lead_id = params[:lead_id]
	@guest_id = params[:guest_id]
	@payment_method_id = params[:payment_method_id]
	@request_type = params[:request_type] #Charge or Schedule

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

def load_dialer_tokens
	if @recordtype == "DialerLead"
		find_dialer_lead
		find_dialer_payment_method
	elsif @recordtype == "DialerGuest"
		find_dialer_guest
		find_dialer_payment_method
	end
end

def create_dialer_tokens
	if @recordtype == "DialerLead"
		create_dialer_lead_customer_token
		if @responseKind == "OK"
			create_dialer_payment_token
		end
	elsif @recordtype == "DialerGuest"
		create_dialer_guest_customer_token
		if @responseKind == "OK"
			create_dialer_payment_token
		end
	end
end

def process_dialer_payment
	@step1 = ids_or_card
	@step2 = process_payment
	@step3 = report
	@step4 = save_processed_dailer_payment
	@step5 = set_response
	# @step6 = clear
end
