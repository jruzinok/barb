class PTDPaymentDate < Rfm::Base
	config :database => 'PTD17'
	config :layout => 'T54_WEB_PAYMENTDATE'
end

class BCPaymentDate < Rfm::Base
	config :database => 'Data'
	config :layout => 'T54_WEB_PAYMENTDATE'
end

class PTDPaymentMethod < Rfm::Base
	config :database => 'PTD17'
	config :layout => 'T55_WEB_PAYMENTMETHOD'
end

class BCPaymentMethod < Rfm::Base
	config :database => 'Data'
	config :layout => 'T55_WEB_PAYMENTMETHOD'
end

class PTDDirectory < Rfm::Base
	config :database => 'PTD17'
	config :layout => 'T55_WEB_DIRECTORY'
end

class BCDirectory < Rfm::Base
	config :database => 'Data'
	config :layout => 'T55_WEB_DIRECTORY'
end

class DialerPayment < Rfm::Base
	config :database => 'DialerLeads'
	config :layout => 'WEB_PAYMENT'
end

class DialerLead < Rfm::Base
	config :database => 'DialerLeads'
	config :layout => 'WEB_DIALERLEAD'
end

class DialerGuest < Rfm::Base
	config :database => 'DialerLeads'
	config :layout => 'WEB_DIALERGUEST'
end

class DialerPaymentMethod < Rfm::Base
	config :database => 'DialerLeads'
	config :layout => 'WEB_PAYMENTMETHOD'
end
