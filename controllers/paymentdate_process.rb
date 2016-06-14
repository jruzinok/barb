 include AuthorizeNet::API

def transaction
	config = YAML.load_file(File.dirname(__FILE__) + "/../config/credentials.yml")
	Transaction.new(config['api_login_id'], config['api_transaction_key'], :gateway => :production)
end

def charge_credit_card()
	request = CreateTransactionRequest.new
	request.transactionRequest = TransactionRequestType.new()
	request.transactionRequest.amount = @amount
	request.transactionRequest.payment = PaymentType.new
	request.transactionRequest.payment.creditCard = CreditCardType.new(@cardnumber, @carddate, @cardcvv) 
	request.transactionRequest.transactionType = TransactionTypeEnum::AuthCaptureTransaction

	# HARDCODED GL CODES for BCs NEEDS to be updated!
	request.transactionRequest.order = OrderType.new()
	request.transactionRequest.order.invoiceNumber = "BCOMP#{@bc}16"
	request.transactionRequest.order.description = "422"

	response = transaction.create_transaction(request)

	if response.transactionResponse != nil
		if response.messages.resultCode == MessageTypeEnum::Ok
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
