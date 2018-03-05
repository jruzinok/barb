def process_create_dialer_payment_method_request
	parse_create_dialer_payment_method_post
	if @request_type == "Charge"
		create_dialer_tokens
		if @result == "OK"
			process_dialer_payment_date
		end
	elsif @request_type == "Schedule"
		create_dialer_tokens
		if @result == "OK"
			save_scheduled_dailer_payment_date
			create_payment_processor_log
		end
	end

	log_result_to_console
end

# To ONLY create tokens.
def process_create_dialer_payment_method_request_v2
	parse_create_dialer_payment_method_post
	create_dialer_tokens
	log_result_to_console
end

def process_create_dialer_payment_date_request
	parse_create_dialer_payment_method_post
	if @request_type == "Charge"
		load_dialer_tokens
		process_dialer_payment_date
	elsif @request_type == "Schedule"
		load_dialer_tokens
		save_scheduled_dailer_payment_date
		create_payment_processor_log
	end

	log_result_to_console
end

def parse_create_dialer_payment_method_post
	@merchant = params[:merchant]
	@lead_id = params[:lead_id]
	@guest_id = params[:guest_id]
	@payment_method_id = params[:payment_method_id]

	@request_type = params[:request_type] #Charge or Schedule
	
	# GL Codes
	@program = params[:program] # BC/CS/PTD
	@event_abbr = params[:event_abbr] # ATL/DC/FL... [BC ONLY]
	@event_year = params[:event_year] # BC ONLY e.g. 2018

	# This is used to flag Payment Method records.
	@flag_deposit = params[:flag_deposit]
	@flag_recurring = params[:flag_recurring]

	# Grab the values from the POST object.
	@date = params[:Date]
	@amount = params[:Amount]

	# Credit Card
	@card_name_first = params[:Name_First]
	@card_name_last = params[:Name_Last]
	@card_number = params[:CreditCard]
	@card_mmyy = params[:MMYY]
	@card_cvv = params[:CVV]

	log_post_variables_to_console
end

def log_post_variables_to_console
	puts "\n\n\n\n\n"
	puts "----------------------------------------"
	puts "[POST VALUES]"
	puts "----------------------------------------"
	puts "[DATABASE] #{@database}"
	puts "[LEAD] #{@lead_id}"
	puts "[GUEST] #{@guest_id}"
	puts "[PAYMENTMETHOD] #{@payment_method_id}"
	puts "[REQUESTTYPE] #{@request_type}" #Charge or Schedule
	puts "[MERCHANT] #{@merchant}"

	# Grab the values from the POST object.
	puts "[DATE] #{@date}"
	puts "[AMOUNT] #{@amount}"
	
	puts "[FIRST] #{@card_name_first}"
	puts "[LAST] #{@card_name_last}"
	puts "[CARD] #{@card_number}"
	puts "[DATE] #{@card_mmyy}"
	puts "[CVV] #{@card_cvv}"
	puts "[TIMESTAMP] #{Time.now}"
	puts "----------------------------------------"
end

def load_dialer_tokens
	# if @recordtype == "DialerLead"
		find_dialer_lead
		find_dialer_payment_method
	# elsif @recordtype == "DialerGuest"
	# 	find_dialer_guest
	# 	find_dialer_payment_method
	# end
end

def create_dialer_tokens
	create_dialer_lead_customer_token
	if @result == "OK"
		create_dialer_payment_token
	elsif @dialer_lead_found == true && @has_customer_token == true
		create_dialer_payment_token
	end
end

def process_dialer_payment_date
	@step0 = set_gl_codes
	@step1 = process_or_skip
	@step3 = log_result_to_console
	@step4 = save_processed_dailer_payment_date
	@step5 = create_payment_processor_log
	@step6 = set_response
	@step7 = clear_response
end
