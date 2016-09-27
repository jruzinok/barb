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
	puts "\n[DIRECTORY] #{@directory_id}"
	puts "\n[PAYMENTMETHOD] #{@payment_method_id}"
	puts "\n#{@statusMessage}"
	puts "\n[CODE] #{@responseCode}"
	puts "\n[REASON] #{@responseError}"
	puts "\n[TIMESTAMP] #{Time.now.utc.iso8601}"
	puts "\n----------------------------------------"
	puts "\n\n\n\n\n"
end
