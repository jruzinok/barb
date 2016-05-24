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
	request.transactionRequest.transactionType = TransactionTypeEnum::AuthCaptureTransaction
	
	response = transaction.create_transaction(request)

	if response != null
		if response.messages.resultCode == MessageTypeEnum::Ok
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
	else
		@responseKind = "Error"
		@responseMessage = "This payment failed to process"
	end
end
