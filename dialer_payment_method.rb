def create_dialer_payment_token
	find_dialer_lead
 
	if @has_customer_token == true
		create_payment_token
		save_dialer_payment_method
		create_payment_processor_log
	end

	# This sends the PaymentMethodID back to the Dialer php web app in the response body.
	if @result == "OK" && @dailer_payment_method_found == true
		@status_message = @payment_method_id.to_s
	end

	set_response
	# clear_response
end

def find_dialer_payment_method
	@dailer_payment_method = DIALERPaymentMethod.find(:__kP_PaymentMethod => @payment_method_id)

	if @dailer_payment_method[0] != nil
		@dailer_payment_method_found = true
		load_dialer_payment_method
	else
		@dailer_payment_method_found = false
		@status_code = 300
		@status_message = "[ERROR] PaymentMethodRecordNotFound"
		set_response
		log_result_to_console
	end
end

def find_dialer_payment_method_by_payment_token
	@dailer_payment_method = DIALERPaymentMethod.find(:Token_Payment_ID => @payment_token)

	if @dailer_payment_method[0] != nil
		@dailer_payment_method_found = true
		load_dialer_payment_method
	else
		@dailer_payment_method_found = false
		@status_code = 300
		@status_message = "[ERROR] PaymentMethodRecordNotFound"
		set_response
		log_result_to_console
	end
end

def load_dialer_payment_method
	@dailer_payment_method = @dailer_payment_method[0] # Load the record from the first position of the array.
	@payment_method_id = @dailer_payment_method["__kP_PaymentMethod"]
	@payment_token = @dailer_payment_method["Token_Payment_ID"]

	check_payment_token
end

def save_dialer_payment_method
	@dailer_payment_method = DIALERPaymentMethod.new

	@dailer_payment_method[:_kF_DialerLead] = @lead_id
	@dailer_payment_method[:_kF_Guest] = @guest_id
	@dailer_payment_method[:Name_First] = @card_name_first
	@dailer_payment_method[:Name_Last] = @card_name_last
	@dailer_payment_method[:CreditCard_Number] = @card_number
	@dailer_payment_method[:MMYY] = @card_mmyy
	@dailer_payment_method[:CVV] = @card_cvv
	@dailer_payment_method[:zzF_Payment_Deposit] = @flag_deposit
	@dailer_payment_method[:zzF_Payment_Recurring] = @flag_recurring
	@dailer_payment_method[:zzF_Merchant] = @merchant

	if @result == "OK"
		@dailer_payment_method[:Token_Payment_ID] = @payment_token
		@dailer_payment_method[:zzF_Status] = "Active"
		@dailer_payment_method[:zzF_Type] = "Token"
	else
		@dailer_payment_method[:zzPP_Response] = @response
		@dailer_payment_method[:zzPP_Response_Code] = @response_code
		@dailer_payment_method[:zzPP_Response_Error] = @response_error
		@dailer_payment_method[:zzF_Status] = "Inactive"
		@dailer_payment_method[:zzF_Type] = "Error"
	end

	@dailer_payment_method.save

	# GRAB the ID from the newly created PaymentMethod.
	if @result == "OK"
		find_dialer_payment_method_by_payment_token
	end
end

def set_stash_to_id
	@payment_method_id_stash = @payment_method_id
end

def set_link_to_stash
	@payment_method_id_link = @payment_method_id_stash
end

def set_id_to_link
	@payment_method_id = @payment_method_id_link
end

def link_dialer_payment_methods
	set_link_to_stash
	link_dialer_payment_method
	set_stash_to_id
	set_id_to_link
	find_dialer_payment_method
	set_link_to_stash
	link_dialer_payment_method
end

def link_dialer_payment_method
	@dailer_payment_method[:_kF_PaymentMethod_DL] = @payment_method_id_link
	@dailer_payment_method.save
end
