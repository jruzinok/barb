def create_customer_token_logic
	if check_required_ct_params
		prepare_customer_variables
		@check_by_merchant_id = true
		validate_customer_token

		if @has_customer_token == false
			clear_response
			create_customer_token
		elsif @has_customer_token == true && @result == "OK"
			@result = "OK"
			@status_code = 230
			@status_message = "[OK] CustomerTokenAlreadyExisted"
			@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message,"customer_token"=>@customer_token][0]
		end

	else
		@result = "ERROR"
		@status_code = 194
		@status_message = "[ERROR] Missing required JSON variables."
		@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message][0]
	end
end

def create_payment_token_logic
	if check_required_pt_params
		prepare_payment_variables
		@check_by_customer_token = true
		validate_customer_token

		if @has_customer_token == true && @result == "OK"
			clear_response
			create_payment_token
		else
			@result = "ERROR"
			@status_code = 195
			@status_message = "[ERROR] CustomerTokenDoesntExist"
			@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message][0]
		end

	else
		@result = "ERROR"
		@status_code = 193
		@status_message = "[ERROR] Missing required JSON variables."
		@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message][0]
	end
end

def list_payment_token_logic
	if check_required_list_params
		prepare_list_payment_variables
		@check_by_customer_token = true
		validate_customer_token

		if @has_customer_token == true && @result == "OK"
			build_array_of_payment_tokens
			@result = "OK"
			@status_code = 210
			@status_message = "[OK] PaymentTokensRetrieved"
			@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message,"customer_token"=>@customer_token,"payment_tokens"=>@tokens][0]
		else
			@result = "ERROR"
			@status_code = 194
			@status_message = "[ERROR] CustomerTokenDoesntExist"
			@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message][0]
		end

	else
		@result = "ERROR"
		@status_code = 192
		@status_message = "[ERROR] Missing required JSON variables."
		@return_json_package = JSON.generate ["result"=>@result,"status_code"=>@status_code,"status_message"=>@status_message][0]
	end
end

def build_array_of_payment_tokens
	@customer_token = @authorize_response.profile.customerProfileId
	@payment_tokens = @authorize_response.profile.paymentProfiles

	if @payment_tokens.length >= 1
		@tokens = Array.new
		@i = 0

		@payment_tokens.each do |p|
			@tokens[@i] = {'payment_token' => p.customerPaymentProfileId, 'card_number'=> p.payment.creditCard.cardNumber}
			@i += 1
		end
	end
end

def check_required_ct_params
	if @json[:filemaker_id] && @json[:merchant] && @json[:name_first] && @json[:name_last] && @json[:program]
		true
	else
		false
	end
end

def check_required_pt_params
	if @json[:customer_token] && @json[:card_number] && @json[:card_mmyy] && @json[:card_cvv] && @json[:merchant] && @json[:name_first] && @json[:name_last]
		true
	else
		false
	end
end

def check_required_list_params
	if @json[:customer_token]
		true
	else
		false
	end
end

def prepare_customer_variables
	@merchant = @json[:merchant]
	@customer = "#{@json[:program]}#{@json[:filemaker_id]}" # The "ID" used to create a customer profile.
	@name_full = "#{@json[:name_first]} #{@json[:name_last]}"
end

def prepare_list_payment_variables
	@customer_token = @json[:customer_token]
end

def prepare_payment_variables
	@merchant = @json[:merchant]
	@customer_token = @json[:customer_token]
	@card_name_first = @json[:name_first]
	@card_name_last = @json[:name_last]
	@card_number = @json[:card_number]
	@card_mmyy = @json[:card_mmyy]
	@card_cvv = @json[:card_cvv]
	@phone = @json[:phone_number]
	@address = @json[:address_street]
	@city = @json[:address_city]
	@state = @json[:address_state]
	@zip = @json[:address_zip]
end
