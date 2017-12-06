def load_merchant_vars
	load_merchant_from_yml
	# load_merchant_from_env
	load_gateway
	transaction_ready
end

def load_merchant_from_yml
	# LOAD the Authorize.net api credentials.
	credentials = YAML.load_file(File.dirname(__FILE__) + "/config/credentials.yml")
	@gateway = credentials['gateway']

	if @merchant == "BAR"
		@merchant_credentials_loaded = true
		@api_login_id = credentials['api_login_id_bar']
		@api_transaction_key = credentials['api_transaction_key_bar']
	elsif @merchant == "PTD"
		@merchant_credentials_loaded = true
		@api_login_id = credentials['api_login_id_ptd']
		@api_transaction_key = credentials['api_transaction_key_ptd']
	else
		@merchant_credentials_loaded = false
	end
end

def load_merchant_from_env
	@gateway = ENV['AUTHORIZE_API_ENDPOINT']

	if @merchant == "BAR"
		@merchant_credentials_loaded = true
		@api_login_id = ENV['AUTHORIZE_API_ID_BC']
		@api_transaction_key = ENV['AUTHORIZE_API_KEY_BC']
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
	if @merchant_credentials_loaded == true && @merchant_gateway_loaded == true && @api_login_id != nil && @api_transaction_key != nil && @gateway != nil
		true
	else
		false
	end
end

def transaction_ok
	if transaction_ready == false
		false
	elsif @response.messages.resultCode == MessageTypeEnum::Ok
		@result = "OK"
		true
	else
		response_kind_error
	end
end

def response_kind_error
	@result = "ERROR"
	@response_code = @response.messages.messages[0].code
	@response_error = @response.messages.messages[0].text
end
