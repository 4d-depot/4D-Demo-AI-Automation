// EmailAnalyzer.4dm
// Email routing: identifies the type and context without an AI call
// AI only intervenes after pre-qualification

singleton Class constructor()

// ─── Search for candidate events for a modification ───────────────────────────
// Searches by sender email, then by date or reference mentioned in the body
Function _findCandidateEvents($email : cs.EmailEntity) : Collection
	var $candidates : Collection:=[]

	// 1) Find the client by sender email
	var $clientEmail : Text:=$email.senderEmail
	var $client : cs.ClientEntity:=ds.Client.query("email = :1"; $clientEmail).first()
	If ($client=Null)
		return $candidates
	End if

	// 2) Get their future events (status confirmed or quote)
	var $today : Date:=Current date
	var $events : cs.EventSelection:=ds.Event.query(\
		"clientID = :1 AND eventDate >= :2 AND (status = :3 OR status = :4)"; \
		$client.ID; $today; "confirmed"; "quote"\
	).orderBy("eventDate ASC")

	// 3) Score each event based on mentions in the body
	var $body : Text:=Lowercase($email.body)
	var $subject : Text:=Lowercase($email.subject)

	var $evt : cs.EventEntity
	var $score : Integer
	var $ref : Text
	var $dateStr : Text
	var $venue : cs.VenueEntity
	var $venueName : Text
	var $venueCity : Text
	For each ($evt; $events)
		$score:=0
		$ref:=Lowercase($evt.contractRef)
		$dateStr:=String($evt.eventDate; "yyyy-MM-dd")

		// Reference mention
		If ((Position($ref; $body)>0) || (Position($ref; $subject)>0))
			$score:=$score+10
		End if

		// Date mention
		If (Position($dateStr; $body)>0)
			$score:=$score+5
		End if

		// Venue name mention
		$venue:=$evt.venue
		If ($venue#Null)
			$venueName:=Lowercase($venue.name)
			$venueCity:=Lowercase($venue.city)
			If ((Position($venueCity; $body)>0) || (Position($venueCity; $subject)>0))
				$score:=$score+3
			End if
			If (Position($venueName; $body)>0)
				$score:=$score+4
			End if
		End if

		// Always include if score > 0, or if < 3 future events (small portfolio)
		If (($score>0) || ($events.length<=3))
			$candidates.push({eventID: $evt.ID; contractRef: $evt.contractRef; eventDate: String($evt.eventDate; "yyyy-MM-dd"); venueName: (Choose($venue#Null; $venue.name; "")); guestCount: $evt.guestCount; score: $score})
		End if
	End for each

	// Sort by descending score
	$candidates:=$candidates.orderBy("score desc")

	// Limit to 4 candidates max
	If ($candidates.length>4)
		$candidates:=$candidates.slice(0; 4)
	End if

	return $candidates

// ─── Builds the candidate collection for AIAdvisor ────────────────────────────
Function buildCandidateCollection($email : cs.EmailEntity) : Collection
	return This._findCandidateEvents($email)

// ─── Loads event lines for the AI prompt ───────────────────────────────────────
Function buildEventLinesCollection($eventID : Text) : Collection
	var $lines : Collection:=[]
	var $selection : cs.EventLineSelection:=ds.EventLine.query("eventID = :1"; $eventID)
	var $line : cs.EventLineEntity
	var $service : cs.ServiceEntity
	For each ($line; $selection)
		$service:=$line.service
		$lines.push({serviceID: $line.serviceID; serviceLabel: (Choose($service#Null; $service.label; "Unknown")); quantity: $line.quantity; unitPrice: $line.unitPrice})
	End for each
	return $lines
