class PTDPaymentDate < Rfm::Base
	config :database => 'PTD16'
	config :layout => 'T54_WEB_PAYMENTDATE'
end

class BCPaymentDate < Rfm::Base
	config :database => 'Data'
	config :layout => 'T54_WEB_PAYMENTDATE'
end
