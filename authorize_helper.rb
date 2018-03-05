def load_merchant_variables
	if ENV['CLOUD'] == "Heroku"
		load_merchant_from_env
	else
		load_merchant_from_yml
	end
	load_gateway
end

def load_merchant_from_yml
	# LOAD the Authorize.net api credentials.
	credentials = YAML.load_file(File.dirname(__FILE__) + "/config/credentials.yml")
	@gateway = credentials['authorize_api_gateway']

	if @merchant == "BAR"
		@merchant_credentials_loaded = true
		@api_login_id = credentials['authorize_api_id_bar']
		@api_transaction_key = credentials['authorize_api_key_bar']
	elsif @merchant == "PTD"
		@merchant_credentials_loaded = true
		@api_login_id = credentials['authorize_api_id_ptd']
		@api_transaction_key = credentials['authorize_api_key_ptd']
	else
		@merchant_credentials_loaded = false
	end
end

def load_merchant_from_env
	@gateway = ENV['AUTHORIZE_API_GATEWAY']

	if @merchant == "BAR"
		@merchant_credentials_loaded = true
		@api_login_id = ENV['AUTHORIZE_API_ID_BAR']
		@api_transaction_key = ENV['AUTHORIZE_API_KEY_BAR']
	elsif @merchant == "PTD"
		@merchant_credentials_loaded = true
		@api_login_id = ENV['AUTHORIZE_API_ID_PTD']
		@api_transaction_key = ENV['AUTHORIZE_API_KEY_PTD']
	else
		@merchant_credentials_loaded = false
	end
end

def load_gateway
	if @gateway == "production"
		@merchant_gateway_loaded = true
		@gateway = {:gateway => :production}
	elsif @gateway == "sandbox"
		@merchant_gateway_loaded = true
		@gateway = {:gateway => :sandbox, :verify_ssl => true}
	else
		@merchant_gateway_loaded = false
		@gateway = nil
	end
end

def transaction_ready
	load_merchant_variables
	if @merchant_credentials_loaded == true && @merchant_gateway_loaded == true && @api_login_id != nil && @api_transaction_key != nil && @gateway != nil
		true
	else
		transaction_not_ready
		false
	end
end

def transaction_not_ready
	@result = "ERROR"
	@status_code = 99
	@status_message = "[ERROR] Merchant variables are missing."
	copy_status_variables_to_response_variables
	@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message][0]
end

def transaction_ok
	begin # This ensures that a response was received before proceeding.
		if @authorize_response.messages.resultCode == MessageTypeEnum::Ok
			@result = "OK"
			true
		else
			transaction_error
			false
		end

	rescue NoMethodError, Errno::ETIMEDOUT => e
		transaction_failure
		false
	end
end

def transaction_error
	@result = "ERROR"
	@authorize_response_code = @authorize_response.messages.messages[0].code
	@authorize_response_message = @authorize_response.messages.messages[0].text

	clean_authorize_response_message
end

def transaction_failure
	@result = "FAILURE"
	@status_code = 98
	@status_message = "[ERROR] A transactional FAILURE occurred."
	copy_status_variables_to_response_variables
	@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message,"authorize_response_code"=>@authorize_response_message,"authorize_response_message"=>@authorize_response_message][0]
end

def copy_status_variables_to_response_variables
	# Because a response was NOT received, this ensures that the records are marked accordingly.
	@authorize_response_code = @status_code
	@authorize_response_message = @status_message
end

def transaction_payment_ok
	@authorize_response_code = @authorize_response.messages.messages[0].code
	@authorize_response_message = @authorize_response.messages.messages[0].text

	clean_authorize_response_message
end

def transaction_payment_error
	if @authorize_response.transactionResponse.errors != nil
		@authorize_response_code = @authorize_response.transactionResponse.errors.errors[0].errorCode
		@authorize_response_message = @authorize_response.transactionResponse.errors.errors[0].errorText

		clean_authorize_response_message
	else
		@result = "ERROR"
		@authorize_response_kind = "TransactionError"
		@authorize_response_code = "010101"
		@authorize_response_message = "No response from Authorize"
	end
end

def clean_authorize_response_message
	@authorize_response_message.sub! "(TESTMODE) ", ""
end
