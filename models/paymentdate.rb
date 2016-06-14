class PTDPaymentDate < Rfm::Base
	config :database => 'PTD16'
	config :layout => 'T54_WEB_PAYMENTDATE'
end

class BCPaymentDate < Rfm::Base
	config :database => 'Data'
	config :layout => 'T54_WEB_PAYMENTDATE'
end

# This "model" is used to initiate the second half of the Payment Process by calling the "Report" portion of the Payment Processor Tool script.
class PPPaymentDate < Rfm::Base
	config :database => 'Payment Processing'
	config :layout => 'T54_WEB_PAYMENTDATE'
end
