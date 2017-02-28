def check_customer_token
	if @customer_token != nil
		@has_customer_token = true
	else
		@has_customer_token = false
	end
end

def check_payment_token
	if @payment_token != nil
		@has_payment_token = true
	else
		@has_payment_token = false
	end
end

# This determines whether or not to process this payment or not.
def process_or_skip

	# Check if this payment is by ids or card.
	card_or_token

	if @card_or_tokens == "tokens" || @card_or_tokens == "card"
		@process_or_skip = "Process"
		process_payment
	else
		@process_or_skip = "Skip"
	end
end

# This determines if this transaction should be processed using Authorize IDs or a CC.
def card_or_token

	# If this record has (Authorize.net) IDs, validate them.
	if @customer_token && @payment_token

		# Validate the IDs.
		validate_tokens

		if @valid_tokens == true
			@card_or_tokens = "tokens"
		else
			@card_or_tokens = "error"
		end

	# If this record has credit card values, use them.
	else
		@card_or_tokens = "card"
	end
end

# SET the GL Codes.
def set_gl_codes
	if @database == "PTD" || @database == "DL"
		ptd_gl_code
	elsif @database == "BC"
		bc_gl_code
	elsif @database == "CS"
		cs_gl_code
	end
end

# This GL Code is referenced in the process_payment method.
# This GL Code is used to categorize tranasactions.
def ptd_gl_code
	date = Time.now
	month = date.month
	year = date.year
	nextyear = year + 1

	# October is when the GL Code swithces to 424.
	month_ptd = 10

	if (month >= month_ptd)
		@gl_code = "424"
		@invoice = "PTD#{short_year(nextyear)}"
	else
		@gl_code = "423"
		@invoice = "PTD#{short_year(year)}"
	end

end

def bc_gl_code
	date = Time.now
	year = date.year

	@gl_code = "422"
	@invoice = "BCOMP#{@eventAbbr}#{short_year(year)}"
end

def cs_gl_code
	date = Time.now
	year = date.year

	unless @classdate.nil?
		if @today < @classdate
			@gl_code = "403"
		elsif @today < @classdate + 7
			@gl_code = "402"
		else
			@gl_code = "401"
		end
	else
		@gl_code = "401"
	end

	# @invoice is set in the load_payment_date method for CS records.
end

def short_year (yr)
	yr.to_s.split(//).last(2).join("").to_s
end

def set_response
	@status = @statusCode
	@body = @statusMessage
end

def clear_response
	@theResponse = nil
	@responseKind = nil
	@responseCode = nil
	@responseError = nil
	@resultCode = nil
	@avsCode = nil
	@cvvCode = nil
	@transactionID = nil
	@authorizationCode = nil
	@responseMessage = nil
	@responseError = nil
end

def log_error_to_console
	puts "\n\n\n\n\n"
	puts "----------------------------------------"
	puts "[DATABASE] #{@database}"
	if @database == "BC" || @database == "CS" || @database == "PTD"
		puts "[DIRECTORY] #{@directory_id}"
		puts "[PAYMENTMETHOD] #{@payment_method_id}"
		puts "[PAYMENTDATE] #{@payment_date_id}"
	elsif @database == "DL"
		puts "[LEAD] #{@lead_id}"
		puts "[GUEST] #{@guest_id}"
	end
	puts "#{@statusMessage}"
	puts "[CODE] #{@responseCode}"
	puts "[REASON] #{@responseError}"
	puts "[TIMESTAMP] #{Time.now.utc.iso8601}"
	puts "[GLCODE] #{@gl_code}"
	puts "[INVOICE] #{@invoice}"
	puts "[CLASSDATE] #{@classdate}"
	puts "----------------------------------------"
	puts "\n\n\n\n\n"
end

def log_result_to_console

	# This determines what to output, either the authorization or error data.
	responseOutput =
	if @responseKind == "Approved"
		"Authorization: #{@authorizationCode}"
	else
		"Error: #{@responseError}"
	end

	# This determines what to output, either the card number or customer profile and payment ids.
	paymentMethod =
	if @card_or_tokens == "tokens"
		"Profile: #{@customer_token} Payment: #{@payment_token}"
	elsif @card_or_tokens == "card"
		"Card: #{@cardnumber}"
	else
		"Error"
	end

	puts "\n[RESPONSE] #{@responseKind}"
	puts "[MESSAGE] #{responseOutput}"
	puts "[CODE] #{@responseCode}"
	puts "[RECORD] #{@serial}"
	puts "[DIRECTORY] #{@directory_id}"
	puts "[PAYMENTMETHOD] #{@payment_method_id}"
	puts "[METHOD] #{paymentMethod}"
	puts "[P or S] #{@process_or_skip}"
	puts "[GLCODE] #{@gl_code}"
	puts "[INVOICE] #{@invoice}"
	puts "[CLASSDATE] #{@classdate}"
	puts "\n----------------------------------------"
end
