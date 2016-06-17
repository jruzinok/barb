 include AuthorizeNet::API

def transaction
	config = YAML.load_file(File.dirname(__FILE__) + "/../config/credentials.yml")
	Transaction.new(config['api_login_id'], config['api_transaction_key'], :gateway => :sandbox)
end

def charge_credit_card()
	request = CreateTransactionRequest.new
	request.transactionRequest = TransactionRequestType.new()
	request.transactionRequest.amount = @amount
	request.transactionRequest.payment = PaymentType.new
	request.transactionRequest.payment.creditCard = CreditCardType.new(@cardnumber, @carddate, @cardcvv)

	# Contestant First and Last Names + Address
	request.transactionRequest.billTo = BillTo.new()
	request.transactionRequest.billTo.firstName = @namefirst
	request.transactionRequest.billTo.lastName = @namelast
	request.transactionRequest.billTo.address = @address
	request.transactionRequest.billTo.city = @city
	request.transactionRequest.billTo.state = @state
	request.transactionRequest.billTo.zip = @zip
	request.transactionRequest.billTo.country = "US"

	request.transactionRequest.transactionType = TransactionTypeEnum::AuthCaptureTransaction

	# HARDCODED GL CODES for BCs NEEDS to be updated!
	request.transactionRequest.order = OrderType.new()
	request.transactionRequest.order.invoiceNumber = "BCOMP#{@bc}16"
	request.transactionRequest.order.description = "422"

	response = transaction.create_transaction(request)

	if response.transactionResponse != nil
		if response.messages.resultCode == MessageTypeEnum::Ok

				# Capture the response variables for all transactions.
				@response = response
				@avsCode = response.transactionResponse.avsResultCode
				@cvvCode = response.transactionResponse.cvvResultCode

			if response.transactionResponse.authCode != "000000"
				@responseKind = "OK"
				@transactionID = response.transactionResponse.transId
				@authorizationCode = response.transactionResponse.authCode
			else
				@responseKind = "Error"
				@transactionID = response.transactionResponse.transId
				@responseCode =  response.transactionResponse.errors.errors[0].errorCode
				@responseMessage = response.messages.messages[0].text
				@responseError =  response.transactionResponse.errors.errors[0].errorText
			end
		end

	else
		@responseKind = "Failure"
		@responseMessage = "This payment failed to process"
	end
end
