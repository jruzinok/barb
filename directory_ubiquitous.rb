def compare_related_directories
	find_directory
	load_related_directory_key
	set_related_target_database
	stash_directory
	switch_to_related_directory
	find_directory
	compare_merchant_details
end

def load_related_directory_key
	if @database == "BC" || @database == "CS"
		@related_directory_id = @directory["_kF_Directory_PTD"]
	elsif @database == "PTD"
		@related_directory_id = @directory["_kF_Directory_DATA"]
	end
end

def set_related_target_database
	if @database == "DATA" || @database == "BC" || @database == "CS"
		@target_database = "PTD"
	elsif @database == "PTD"
		@target_database = "DATA"
	else
		"ERROR"
	end
end

def stash_directory
	@stash_database = @database
	@stash_directory_id = @directory_id
	@stash_d_merchant_id = @d_merchant_id
	@stash_customer_token = @customer_token
end

def switch_to_related_directory
	@directory_id = @related_directory_id
	@database = @target_database
end

def compare_merchant_details
	if 	@stash_d_merchant_id == @d_merchant_id && @stash_customer_token == @customer_token
		@merchant_details = "SAME"
		@payment_tokens_needed = 1
	else
		@merchant_details = "DIFFERENT"
		@payment_tokens_needed = 2
	end
end
