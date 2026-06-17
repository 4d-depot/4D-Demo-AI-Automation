// EventLogger.4dm
// Session singleton writes per-event per-day log files.
// File naming: YYYY-MM-DD-Event-{contractRef}.log (e.g. 2026-06-08-Event-CTR-2026-203.log)
// All activity on the same event within the same day is appended to the same file.
// Covers: user actions, AI system prompts, user prompts, tool calls, tool results, AI responses.

session singleton Class constructor()
	// No state needed files are opened on demand

// ─── Public API ───────────────────────────────────────────────────────────────

// Single-line entry: [HH:MM:SS] [TAG] message
Function log($contractRef : Text; $tag : Text; $message : Text)
	var $nl : Text:=Char(10)
	var $line : Text:="["+String(Current time)+"] ["+$tag+"] "+$message+$nl
	This._append($contractRef; $line)

// Multi-line block: header line then indented content then a separator
Function logBlock($contractRef : Text; $tag : Text; $title : Text; $content : Text)
	var $nl : Text:=Char(10)
	var $ts : Text:="["+String(Current time)+"] "
	var $sep : Text:="──────────────────────────────────────────────────────────────────────"+$nl
	var $block : Text:=$ts+"["+$tag+"] "+$title+$nl
	$block:=$block+$content
	If (Substring($block; Length($block))#$nl)
		$block:=$block+$nl
	End if 
	$block:=$block+$sep
	This._append($contractRef; $block)

// Writes a header banner when the file is first created for this event+day
// Call this before the first log entry for a session on this event
Function logEventHeader($event : cs.EventEntity)
	var $file : 4D.File:=This._getFile($event.contractRef)
	If ($file.exists)
		return   // Header already written today
	End if 
	var $nl : Text:=Char(10)
	var $venue : cs.VenueEntity:=$event.venue
	var $client : cs.ClientEntity:=$event.client
	var $line1 : Text:="════════════════════════════════════════════════════════════════════════"+$nl
	var $header : Text:=$line1
	$header:=$header+"  EVENT LOG "+$event.contractRef+$nl
	$header:=$header+"  Date:    "+String($event.eventDate; "yyyy-MM-dd")+$nl
	$header:=$header+"  Client:  "+($client ? $client.companyName : "")+$nl
	$header:=$header+"  Venue:   "+($venue ? $venue.name+" – "+$venue.city+", "+$venue.country : "")+$nl
	$header:=$header+"  Guests:  "+String($event.guestCount)+$nl
	$header:=$header+"  Option:  "+$event.venueOption+$nl
	$header:=$header+"  Log day: "+String(Current date; "yyyy-MM-dd")+$nl
	$header:=$header+$line1+$nl
	This._append($event.contractRef; $header)

// ─── Private ──────────────────────────────────────────────────────────────────

Function _append($contractRef : Text; $text : Text)
	var $file : 4D.File:=This._getFile($contractRef)
	$file.setText($file.exists ? ($file.getText()+$text) : $text)

// Returns the log file for the given contractRef + today's date
Function _getFile($contractRef : Text) : 4D.File
	var $date : Text:=String(Current date; "yyyy-MM-dd")
	// Sanitize contractRef: replace path-unsafe characters with hyphens
	var $safeRef : Text:=$contractRef
	$safeRef:=Replace string($safeRef; "/"; "-")
	$safeRef:=Replace string($safeRef; Char(92); "-")
	$safeRef:=Replace string($safeRef; ":"; "-")
	return Folder(fk logs folder).file($date+"-Event-"+$safeRef+".log")

