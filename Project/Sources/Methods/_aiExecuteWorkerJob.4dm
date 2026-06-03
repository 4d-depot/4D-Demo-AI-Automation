#DECLARE($window : Integer; $hiddenPrompt : Text; $contextJson : Text; $actionJson : Text)
// Runs in a worker — calls AI execute action then notifies the EventDetail form

var $context : Object:=JSON Parse($contextJson)
var $action : Object:=JSON Parse($actionJson)
var $w : Integer:=$window

// JSON Parse may auto-convert "yyyy-MM-dd" strings to 4D Date type — normalize back to Text
If (Value type($context.eventDate)=Is date)
	$context.eventDate:=String(Date($context.eventDate); "yyyy-MM-dd")
End if 

// Capture actionJson explicitly in an object so the closure survives the async callback
var $captured : Object:={w: $w; actionJson: $actionJson}

var $advisor : cs.AIAdvisor:=cs.AIAdvisor.new()
$advisor.executeActionAsync($hiddenPrompt; $context; \
	Formula(CALL FORM($captured.w; Formula(Form._onExecutionDone($1; JSON Parse($2))); $1; $captured.actionJson)))
