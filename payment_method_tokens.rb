def validate_multiple_tokens
	# This outputs the batch id. It's used to display acts as the header or beginning of the process
	puts "\n\n\n\n\n"
	puts "----------------------------------------"
	puts "[DATABASE] #{@database}"
	puts "[VALIDATE TOKENS]"
	puts "[BATCH] #{@batch}"
	puts "[TIMESTAMP] #{Time.now}"
	puts "----------------------------------------"

	find_payment_methods_by_batch

	@payment_methods.each do |pm|
		@payment_method = pm

		@step1 = load_payment_method
		@step2 = capture_related_directory_id
		@step3 = find_directory
		@step4 = validate_tokens
		# @step5 = create_payment_processor_log
		@step6 = save_payment_method_token_validation_result
		@step7 = clear_response
	end

end

def find_payment_methods_by_batch
	if @database == "DATA" || @database == "BC" || @database == "CS"
		@payment_methods = DATAPaymentMethod.find(:zzF_Batch => @batch)
	elsif @database == "PTD"
		@payment_methods = PTDPaymentMethod.find(:zzF_Batch => @batch)
	end
	
end

def capture_related_directory_id
	@directory_id = @payment_method["_kF_Directory"]
end

def save_payment_method_token_validation_result
	if @valid_tokens == true
		@payment_method[:zzF_Validated] = "Valid"
		@payment_method[:zzF_Status] = "Active"
		@payment_method[:zzF_Type] = "Token"
	else
		@payment_method[:zzPP_Response] = @theResponse
		@payment_method[:zzPP_Response_Code] = @responseCode
		@payment_method[:zzPP_Response_Error] = @responseError
		@payment_method[:zzF_Validated] = "NotValid"
		@payment_method[:zzF_Status] = "Inactive"
		@payment_method[:zzF_Type] = "Error"
	end

	@payment_method.save
end
