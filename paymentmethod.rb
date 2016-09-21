def create_payment
	find_directory

	if @record_found = true && @has_customer_profile == true
		request = CreateCustomerPaymentProfileRequest.new
		creditcard = CreditCardType.new(@cardnumber,@carddate,@cardcvv)
		payment = PaymentType.new(creditcard)
		profile = CustomerPaymentProfileType.new(nil,nil,payment,nil,nil)
		profile.billTo = CustomerAddressType.new
		profile.billTo.firstName = @namefirst
		profile.billTo.lastName = @namelast
		profile.billTo.address = @address
		profile.billTo.city = @city
		profile.billTo.state = @state
		profile.billTo.zip = @zip
		request.paymentProfile = profile
		request.customerProfileId = @profile_id

		@response = transaction.create_customer_payment_profile(request)

		# The transaction has a response.
		if @response.messages.resultCode == MessageTypeEnum::Ok
			@responseKind = "OK"
			@payment_id = @response.customerPaymentProfileId
		else
			@responseKind = "ERROR"
			@responseError = @response.messages.messages[0].text
		end

		create_payment_method
		clear_response
	end
end

#TBD: Create new PaymentMethod record.
# This will need the PayingPerson's DirectoryID, not the Contestant's DirectoryID.
# def create_payment_method
# 	if @responseKind == "OK"
# 		@paymentmethod[:Token_Payment_ID] = @payment_id
# 	else
# 		@paymentmethod[:zzPP_Response] = @response
# 		@paymentmethod[:zzPP_Response_Code] = @responseCode
# 		@paymentmethod[:zzPP_Response_Error] = @responseError
# 	end
# end

# 	@paymentmethod.save
# end

def clear_response
	@response = ""
	@responseKind = ""
	@responseCode = ""
	@responseError = ""
end