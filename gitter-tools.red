Red []

do %gitter-api.red

fix-mold: func [
	"Do some changes to texts in messages block, so mold wouldn't produce garbage"
	value
	/only
][
	forall value [
		replace/all value/1/text #"{" "^^{"
		replace/all value/1/text #"}" "^^}"

		replace/all value/1/html #"{" "^^{"
		replace/all value/1/html #"}" "^^}"
	]
	either only [mold/only value][mold value]
]

select-by: function [
	"Select map! or object! in series by it's field"
	series
	word
	value
] [
	foreach item series [
		if equal? item/:word value [return item]
	]
	none
]

init-gitter: does [
	do load %options.red
	user: gitter/user-info
	rooms: gitter/user-rooms user/id
	room: select-room rooms "red/red" ; Remove later
]

select-room: function [
	"Selects room by its name. Returns room ID."
	rooms "Block of rooms"
	name  "Name of room"
	/by	  "Select room by different field than name"
		field
] [
	unless by [field: 'name]
	foreach room rooms [if equal? name room/:field [return room]]
	none
]

list-rooms: function [
	rooms
] [
	foreach room rooms [
		print room/name
	]
]

get-message-author: func [message][
	any [all [message/fromUser message/fromUser/username] message/author]
]

strip-message: function [
	"Remove unnecessary informations from message"
	message
] [
	message/html: none
	message/author: get-message-author message
	message/fromUser: none
	if empty? message/mentions [message/mentions: none]
	if empty? message/urls [message/urls: none]
	if empty? message/issues [message/issues: none]
	message/unread: none
	message/readBy: none
	message/meta: none
]

; TODO: split this in multiple functions
download-room: func [
	room ; TODO support ID here and better conversion of different types
	/compact "Remove some unnecessary fields"
	/force "Do not use cached messages and re-download everything"
	/verbose "Inform what is going on"
	/to
		filename
	/with
		cache [block!] "If we have messages in memory, we can save lot of time"
	/local info ret last-id newest messages t
] [
	ret: copy []
	; some preparation
	info: func [value /no-line] [if verbose [either no-line [prin value][print value]]]
	if path? room [room: gitter/get-room-info room]
	unless exists? %messages/ [make-dir %messages/]
	unless to [
		filename: rejoin [%messages/ room/id %.red]
	]
	info/no-line ["^/Download messages for room" room/name "..."]
	; load cached messages, when required
	either with [
		ret: cache
	][
		info ["Checking cached file" filename]
		if all [not force exists? filename] [
			t: now/time/precise
			info/no-line ["Loading file" filename "..."]
			ret: append copy [] load filename
			info [length? ret "messages w loaded in" now/time/precise - t]
		]
	]

	either empty? ret [
		info "Downloading all messages"
		; we have no messages, so we will downloaded them
		; from newest to oldest (that's how Gitter works)

		; load first bunch of messages
		ret: gitter/get-messages room
		if empty? ret [
			; the room is empty
			write filename ""
			return none
		]
		if compact [foreach message ret [strip-message message]]
		last-id: ret/1/id

		write filename mold/only ret
		until [
			info/no-line ["Downloading messages before" ret/1/sent "..."]
			ret: gitter/get-messages/with room [beforeId: last-id]
			info [length? ret "messages downloaded."]
			if compact [foreach message ret [strip-message message]]
			unless empty? ret [
				last-id: ret/1/id
		; FIXME: This is workaround for missing MOLD/ALL
		;		"{" and "}" are not escaped and can't be loaded back
		;		so we're going to escape them manually
				write/append filename mold/only reverse ret
				ret: reverse ret
			]
			empty? ret
		]
		ret
	] [
		; we have cached messages, so we will download only newer messages

		; now we will download messages in loop until we have all new messages
		until [
			info/no-line ["Downloading messages posted after" ret/1/sent "..."]
			; NOTE: [afterId] returns messages from oldest to newest, so we need
			;		to reverse the order, to have same format as cached messages
			messages: reverse gitter/get-messages/with
				room
				compose [afterId: (ret/1/id)]
			info [length? messages "messages downloaded."]
			if compact [foreach message ret [strip-message message]]
			insert ret messages ; we may be inserting empty block, but who cares
			empty? messages
		]
		; now save everything (there's no write/insert do do it in loop)
		write filename mold ret
		ret
	]
]

select-message: function [
	"Select message by id"
	messages
	id
] [
	foreach message messages [
		if equal? id message/id [return message]
	]
	none
]

; --- searching

question?: function [
	"Return LOGIC! value indicating whether message contains question mark."
	message
] [
	not not find message/text #"?"
]

get-mentions: function [
	message
][
	name: none
	mentions: copy []
	parse message/text [
		some [
			"@" copy name to space (append mentions name)
		|	skip
		]
	]
	mentions
]

get-code: function [
	"Returns block of code snippets or NONE"
	message
] [
	code: make block! 4
	fence: "```"
	parse message/text [
		some [
			thru fence
			copy value
			to fence
			3 skip
			(append code value)
		]
	]
	either empty? code [none] [code]
]

get-all-code: function [
	messages
] [
	code: make map! []
	foreach message messages [
		code/(message/id): get-code message
	]
	code
]

gfind: func [
	messages
	string
] [
	result: copy []
	foreach message messages [
		if find message/text string [append result message]
	]
	result
]

; ---

get-user-messages: function [
	messages
] [
	users: #()
	template: #(
		posts: 0
		total-chars: 0
		messages: []
	)
	foreach message messages [
		user: message/fromUser/username
		unless users/:user [
			users/:user: copy/deep template
		]
		users/:user/posts: users/:user/posts + 1
		users/:user/total-chars: users/:user/total-chars + length? message/text
		append users/:user/messages message
	]
	users
]

maximum-of: function [
	series
] [
	max: first series
	pos: 1
	forall next series [
		if series/1 > max [
			max: series/1
			pos: index? series
		]
	]
	at series pos
]

red-group-id: "57542d9cc43b8c601977e621"
get-rooms: func [
	"Save room info on disk for later usage"
	group
	/local rooms
][
	rooms: gitter/group-rooms group
	unless exists? %rooms/ [make-dir %rooms/]
	foreach room rooms [
		save rejoin [%rooms/ room/id %.red] room
	]
]

probe-messages: function [
	messages
] [
	foreach message messages [
		print rejoin [get-message-author message " (" message/sent ") wrote:"]
		print "---------------------------------------------------------------"
		print message/text
		print "---------------------------------------------------------------"
		print ""
	]
]

probe-rooms: function [
	rooms
] [
	foreach room rooms [
		print rejoin [room/name ": #" room/id]
	]
]
