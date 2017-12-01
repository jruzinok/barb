def load_merchant_vars
	load_merchant_from_yml
	# load_merchant_from_env
end

def load_merchant_from_yml
	# LOAD the Authorize.net api credentials.
	credentials = YAML.load_file(File.dirname(__FILE__) + "/config/credentials.yml")
	@gateway = credentials['gateway']

	if @merchant == "BC"
		@merchant_credentials_loaded = true
		@api_login_id = credentials['api_login_id_bc']
		@api_transaction_key = credentials['api_transaction_key_bc']
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

	if @merchant == "BC"
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

def gateway
	if @gateway == "production"
		{:gateway => :production}
	elsif @gateway == "sandbox"
		{:gateway => :sandbox, :verify_ssl => true}
	end
end
