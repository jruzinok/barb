def find_event_attendee_by_directory
	@event_attendee = DATAEventAttendee.find(:_kF_Directory => @directory_id)

	if @event_attendee[0] != nil
		@event_attendee_found = true
		@event_attendee = @event_attendee[0] # Load the record from the first position of the array.
		load_event_attendee
	else
		@event_attendee_found = false
		@statusCode = 300
		@statusMessage = "[ERROR] EventAttendeeRecordNotFound"
		set_response
		log_result_to_console
	end
end

def load_event_attendee
	@event_attendee_id = @event_attendee["__kP_EventAttendee"]
	@event_id = @event_attendee["_kF_Event"]
	@event_abbr = @event_attendee["T57_EVENT::Name_Abbreviation"]
end
