def check_customer_token
	if @customer_token != nil
		@has_customer_token = true
	else
		@has_customer_token = false
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
