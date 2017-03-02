Red []

do %gitter-api.red

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

get-all-messages: func [
	room
	/with messages
	/local
		ret last-id
] [
	either with [
		ret: messages
	] [
		messages: make block! 10'000
		ret: get-messages room
	]
	last-id: ret/1/id
	insert messages ret
	until [
	;	ret: get-messages/before room last-id
		ret: get-messages/with room [beforeId: last-id]
		insert messages ret
		save %messages.red messages
		unless empty? ret [
			print ret/1/sent
			last-id: ret/1/id
		]
		empty? ret
	]
	ret
]

download-all-messages: function [
	room
] [
	ret: get-messages room
	last-id: ret/1/id
	write %messages.red mold reverse ret
	until [
		ret: get-messages/with room [beforeId: last-id]
		unless empty? ret [
			print ret/1/sent
			last-id: ret/1/id
			write/append %messages.red mold reverse ret
		]
		empty? ret
	]
]


stats: function [
	messages
] [
	users: #()
	foreach message messages [
		user: message/fromUser/username
		unless users/:user [
			users/:user: 0
		]
		users/:user: users/:user + 1
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

probe-messages: function [
	messages
] [
	foreach message messages [
		print rejoin [message/fromUser/username " (" message/sent ") wrote:"]
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
