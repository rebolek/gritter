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

gitter: context [

any-map?: func [
	"Return TRUE if VALUE is MAP! or OBJECT!"
	value
] [
	any [map? value object? value]
]

get-id: func [
	"Return ID from user or room object/map or pass ID"
	data
] [
	if any-map? data [data: data/id]
	data
]

decode: function [data] [
	first json/decode third data
]

bearer: function [token] [
	rejoin ["Bearer " token]
]

map: function [
	"Make map with reduce/no-set emulation"
	data
] [
	value: none
	parse data: copy data [
		some [
			change set value set-word! (reduce ['quote value])
		|	skip	
		]
	]
	make map! reduce data
]

json-map: func [
	"Return JSON object from specs"
	data
] [
	json/encode map data
]

; ----------------------------------------------------------------------------
;		gitter api
; ----------------------------------------------------------------------------

send: function [
	data
	"Send GET request to gitter API"
	/post "Send POST request"
		post-data
	/put
		put-data
] [
	type: case [
		post ['POST]
		put  ['PUT]
		true ['GET]
	]
	; 
	value: none
	link: copy https://api.gitter.im/v1/
	args-rule: [
		'? (change back tail link #"?")
		some [
			set value set-word! (append link rejoin [form value #"="])
			set value [word! | string! | integer!] (
				if word? value [value: get :value]
				append link rejoin [value #"&"]
			)
		]
	]
	parse append clear [] data [
		some [
			args-rule
		|	set value [set-word! | file!] (append link dirize form value)
		|	set value word! (append link dirize form get :value)	
		]
	]
	remove back tail link
	header: compose/deep [
		(type) [
			Accept: "application/json"
			Authorization: (bearer token)
		]
	]
	if any [post put] [
		insert last header [Content-Type: "application/json"]
		append header json-map any [post-data put-data]
	]
	decode write/info link header
]

; --- groups resource

list-groups: does [
	send %groups
]

group-rooms: func [
	group
] [
	send [%groups group %rooms]
]

; --- rooms resource

user-rooms: function [
	user
] [
	user: get-id user
	send [%user user %rooms]
]

get-room-info: function [
	room "Room name"
] [
	send/post %rooms [uri: room]
]

join-room: function [
	user 
	room ""
	/by-id "Room arg is id instead of name"
] [
	; TODO: use get-id here
	user: get-id user
	unless by-id [room: select get-room-info room 'id]
	send/post [%user user %rooms] [id: room]
]

remove-user: function [
	user
	room
] [
	; TODO: needs DELETE method
]

; TODO: needs PUT method
update-topic: function [
	room
	topic
] [
	send/put [%rooms room] [topic: topic]
]

; TODO: needs PUT method
room-tags: function [
	room
	tags [string! issue! block!]
] [
	unless block? tags [tags: reduce tags]
;	tags: collect [foreach tag tags [keep rejoin [form tag ", "]]]
;	remove/part back back tail tags 2
;	send/put [%rooms room] rejoin [{^{"tags":"} tags {"^}}]
	send/put [%rooms room] json-map [tags: tags]
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
	room: get-id room
	send [%rooms room %users]
]

; --- messages resource

get-messages: function [
	room
	/with "skip, beforeId, afterId, aroundId, limit, q (search query)"
		values
] [
	room: get-id room
	data: copy [%rooms room %chatMessages]
	if with [append data compose [? (values)]]
	send data
]

get-message: function [
	room 	"Room object or ID"
	id 		"Message ID"
] [
	room: get-id room
	send [%rooms room %chatMessages id]
]

send-message: function [
	room
	text
] [
	room: get-id room
	send/post [%rooms room %chatMessages] [text: text]
]

update-message: function [
	room
	text
	id
] [
	room: get-id room
	send/post [%rooms room %chatMessages id] [text: text]
]

; --- user resource

user-info: does [first send %user]

; TODO: make part of get-messages?
list-unread: function [
	user
	room
] [
	user: get-id user
	room: get-id room
	send [%user user %rooms room %unreadItems]
]

mark-as-read: function [
	user
	room
	messages [string! issue! block!]
] [
	user: get-id user
	room: get-id room
	unless block? messages [messages: reduce messages]
	unless empty? messages [
		send/post [%user user %rooms room %unreadItems] [chat: messages]
	]
]

list-orgs: function [
	user
] [
	user: get-id user
	send [%user user %orgs]
]

list-repos: function [
	user
] [
	user: get-id user
	send [%user user %repos]
]

list-channels: function [
	user
] [
	user: get-id user
	; TODO
]

; --- end of Gritter context

]