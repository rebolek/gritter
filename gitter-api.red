Red [
	Title: "Gitter API"
	Author: "Boleslav Březovský"
	File: %gitter-api.red
	Rights: "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
	}
	Date: "23-10-2016"
	Note: {
	}
]

do %json.red

decode: function [data] [
	first json/decode third data
]

bearer: function [token] [
	rejoin ["Bearer " token]
]


; ----------------------------------------------------------------------------
;		gitter api
; ----------------------------------------------------------------------------


; --- groups resource

list-groups: does [
	decode write/info rejoin [https://api.gitter.im/v1/groups] compose/deep [
		GET [
			Accept: "application/json"
			Authorization: (bearer token)
		]
	]
]

group-rooms: func [
	group
] [
	decode write/info rejoin [https://api.gitter.im/v1/groups/ group "/rooms"] compose/deep [
		GET [
			Accept: "application/json"
			Authorization: (bearer token)
		]
	]
]

; --- rooms resource

user-rooms: function [
	user
] [
	decode write/info rejoin [https://api.gitter.im/v1/user/ user {/rooms}] compose/deep [
		GET [
			Accept: "application/json"
			Authorization: (bearer token)
		]
	]
]

join-room: function [
	room	
] [
	write rejoin [https://api.gitter.im/v1/rooms] compose/deep [
		POST [
			Content-Type: "application/json" 
			Accept: "application/json" 
			Authorization: (bearer token)
		]
		(rejoin [{^{"uri":"} room {"^}}])
	]
]

join-room-by-id: function [
	user
	room
] [
	write rejoin [https://api.gitter.im/v1/user/ user "/rooms"] compose/deep [
		POST [
			Content-Type: "application/json" 
			Accept: "application/json" 
			Authorization: (bearer token)
		]
		(rejoin [{^{"id":"} room {"^}}])
	]
]

remove-user: function [
	user
	room
] [
	; TODO: needs DELETE method
]

update-topic: function [
	room
	topic
] [
	write rejoin [https://api.gitter.im/v1/rooms/ room] compose/deep [
		PUT [
			Content-Type: "application/json" 
			Accept: "application/json" 
			Authorization: (bearer token)
		]
		(rejoin [{^{"topic":"} topic {"^}}])
	]
]

room-tags: function [
	room
	tags [string! issue! block!]
] [
	unless block? tags [tags: reduce tags]
	tags: collect [foreach tag tags [keep rejoin [form tag ", "]]]
	remove/part back back tail tags 2
	write rejoin [https://api.gitter.im/v1/rooms/ room] compose/deep [
		PUT [
			Content-Type: "application/json" 
			Accept: "application/json" 
			Authorization: (bearer token)
		]
		(rejoin [{^{"tags":"} tags {"^}}])
	]
]

; TODO: index room

remove-room: function [
	room
] [
	; TODO: needs DELETE method
]

list-users: function [
	room
] [
	decode write/info rejoin [https://api.gitter.im/v1/rooms/ room {/users}] compose/deep [
		GET [
			Accept: "application/json"
			Authorization: (bearer token)
		]
	]
]

; --- messages resource

get-messages: func [
	room
	; TODO: skip, before-id, after-id, around-id, limit, search-query
] [
	decode x: write/info rejoin [https://api.gitter.im/v1/rooms/ room {/chatMessages}] compose/deep [
		GET [
			Accept: "application/json"
			Authorization: (bearer token)
		]
	]	
]

get-message: function [
	room
	id
] [
	decode write/info rejoin [https://api.gitter.im/v1/rooms/ room {/chatMessages/} id] compose/deep [
		GET [
			Accept: "application/json"
			Authorization: (bearer token)
		]
	]	
]

send-message: function [
	room
	text
] [
	write rejoin [https://api.gitter.im/v1/rooms/ room "/chatMessages"] compose/deep [
		POST [
			Content-Type: "application/json" 
			Accept: "application/json" 
			Authorization: (bearer token)
		]
		(rejoin [{^{"text":"} text {"^}}])
	]
]

update-message: function [
	room
	text
	id
] [
	write rejoin [https://api.gitter.im/v1/rooms/ room "/chatMessages/" id] compose/deep [
		POST [
			Content-Type: "application/json" 
			Accept: "application/json" 
			Authorization: (bearer token)
		]
		(rejoin [{^{"text":"} text {"^}}])
	]
]

; --- user resource

user-info: does [
	first decode write/info rejoin [https://api.gitter.im/v1/user] compose/deep [
		GET [
			Accept: "application/json"
			Authorization: (bearer token)
		]
	]
]

list-unread: function [
	user
	room
] [
	decode write/info rejoin [https://api.gitter.im/v1/user/ user "/rooms/" room "/unreadItems"] compose/deep [
		GET [
			Accept: "application/json"
			Authorization: (bearer token)
		]
	]
]

mark-as-read: function [
	user
	room
	messages [string! issue! block!]
] [
	unless block? messages [messages: reduce messages]
	messages: rejoin collect [foreach message messages [keep rejoin [form message {", "}]]]
	insert messages {"}
	remove/part back back back tail messages 3
	write rejoin [https://api.gitter.im/v1/user/ user "/rooms/" room "/unreadItems/"] compose/deep [
		POST [
			Content-Type: "application/json" 
			Accept: "application/json" 
			Authorization: (bearer token)
		]
		(rejoin [{^{"chat":[} messages {]^}}])
	]
]

list-orgs: function [
	user
] [
	decode write/info rejoin [https://api.gitter.im/v1/user user "/orgs"] compose/deep [
		GET [
			Accept: "application/json"
			Authorization: (bearer token)
		]
	]
]

list-repos: function [
	user
] [
	decode write/info rejoin [https://api.gitter.im/v1/user user "/repos"] compose/deep [
		GET [
			Accept: "application/json"
			Authorization: (bearer token)
		]
	]
]

list-channels: function [
	user
] [
	decode write/info rejoin [https://api.gitter.im/v1/user user "/repos"] compose/deep [
		GET [
			Accept: "application/json"
			Authorization: (bearer token)
		]
	]
]