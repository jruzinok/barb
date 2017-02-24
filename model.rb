class PTDPaymentDate < Rfm::Base
	config :database => 'PTD17'
	config :layout => 'T54_WEB_PAYMENTDATE'
end

class PTDTransactionAttempt < Rfm::Base
	config :database => 'PTD17'
	config :layout => 'T56_WEB_TRANSACTIONATTEMPT'
end

class DATATransactionAttempt < Rfm::Base
	config :database => 'Data'
	config :layout => 'T56_WEB_TRANSACTIONATTEMPT'
end

class DATAPaymentDate < Rfm::Base
	config :database => 'Data'
	config :layout => 'T54_WEB_PAYMENTDATE'
end

class PTDPaymentMethod < Rfm::Base
	config :database => 'PTD17'
	config :layout => 'T55_WEB_PAYMENTMETHOD'
end

class DATAPaymentMethod < Rfm::Base
	config :database => 'Data'
	config :layout => 'T55_WEB_PAYMENTMETHOD'
end

class PTDDirectory < Rfm::Base
	config :database => 'PTD17'
	config :layout => 'T55_WEB_DIRECTORY'
end

class DATADirectory < Rfm::Base
	config :database => 'Data'
	config :layout => 'T55_WEB_DIRECTORY'
end

class DATAPaymentProcessorLog < Rfm::Base
	config :database => 'Data'
	config :layout => 'T56__PAYMENTPROCESSORLOG'
end

class DATAEventAttendee < Rfm::Base
	config :database => 'Data'
	config :layout => 'T57_WEB_EVENTATTENDEE'
end

class DIALERPaymentDate < Rfm::Base
	config :database => 'DialerLeads'
	config :layout => 'WEB_PAYMENT'
end

class DIALERLead < Rfm::Base
	config :database => 'DialerLeads'
	config :layout => 'WEB_DIALERLEAD'
end

class DIALERGuest < Rfm::Base
	config :database => 'DialerLeads'
	config :layout => 'WEB_DIALERGUEST'
end

class DIALERPaymentMethod < Rfm::Base
	config :database => 'DialerLeads'
	config :layout => 'WEB_PAYMENTMETHOD'
end

class CURRENTSTUDENTCurrentStudent < Rfm::Base
	config :database => '__CURRENT_STUDENTS'
	config :layout => 'WEB_CURRENT_STUDENT'
end

class CURRENTSTUDENTCreditCard < Rfm::Base
	config :database => '__CURRENT_STUDENTS'
	config :layout => 'WEB_CREDIT_CARD'
end
