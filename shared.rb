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

	if @card_or_token == "ids" || @card_or_token == "card"
		process_payment
	end
end

# This determines if this transaction should be processed using Authorize IDs or a CC.
def card_or_token

	# If this record has (Authorize.net) IDs, validate them.
	if @customer_token && @payment_token

		# Validate the IDs.
		validate_tokens

		if @valid_tokens == true
			@card_or_token = "ids"
		else
			@card_or_token = "Error"
		end

	# If this record has credit card values, use them.
	else
		@card_or_token = "card"
	end
end

def set_response
	@status = @statusCode
	@body = @statusMessage
end

def clear_response
	@theResponse = ""
	@responseKind = ""
	@responseCode = ""
	@responseError = ""
	@resultCode = ""
	@avsCode = ""
	@cvvCode = ""
	@transactionID = ""
	@authorizationCode = ""
	@responseMessage = ""
	@responseError = ""
end

def log_error_to_console
	puts "\n\n\n\n\n"
	puts "\n----------------------------------------"
	puts "\n[DATABASE] #{@database}"
	if @database == "BC" || @database == "PTD"
		puts "\n[DIRECTORY] #{@directory_id}"
		puts "\n[PAYMENTMETHOD] #{@payment_method_id}"
	elsif @database == "DL"
		puts "\n[LEAD] #{@lead_id}"
		puts "\n[GUEST] #{@guest_id}"
	end
	puts "\n#{@statusMessage}"
	puts "\n[CODE] #{@responseCode}"
	puts "\n[REASON] #{@responseError}"
	puts "\n[TIMESTAMP] #{Time.now.utc.iso8601}"
	puts "\n----------------------------------------"
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
	if @card_or_token == "card"
		"Card: #{@cardnumber}"
	else
		"Profile: #{@customer_token} Payment: #{@payment_token}"
	end

	puts "\nRESPONSE: [#{@responseKind}]"
	puts "MESSAGE: #{responseOutput}"
	puts "CODE: #{@responseCode}"
	puts "RECORD: #{@serial}"
	puts "METHOD: #{paymentMethod}"
	puts "\n----------------------------------------"
end