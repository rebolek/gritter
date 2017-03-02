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

map: function [
	"Make map with reduce/no-set emulation"
	data
] [
	value: none
	parse data [
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

send-gitter: function [
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
	parse probe append clear [] data [
		some [
			args-rule
		|	set value [set-word! | file!] (append link probe dirize form value)
		|	set value word! (append link dirize probe get :value)	
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
		append header any [post-data put-data]
	]
	decode write/info probe link probe header
]

; --- groups resource

list-groups: does [
	send-gitter %groups
]

group-rooms: func [
	group
] [
	send-gitter [%groups group %rooms]
]

; --- rooms resource

user-rooms: function [
	user
] [
	send-gitter [%user user %rooms]
]

join-room: function [
	room	
] [
	send-gitter/post %rooms json-map [uri: room]
]

join-room-by-id: function [
	user
	room
] [
	send-gitter/post [%user user %rooms] json-map [id: room]
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
	send-gitter/put [%rooms room] json-map [topic: topic]
]

room-tags: function [
	room
	tags [string! issue! block!]
] [
	unless block? tags [tags: reduce tags]
	tags: collect [foreach tag tags [keep rejoin [form tag ", "]]]
	remove/part back back tail tags 2
;	send-gitter/put [%rooms room] json-map [tags: tags]
	send-gitter/put [%rooms room] rejoin [{^{"tags":"} tags {"^}}]
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
	send-gitter [%rooms room %users]
]

; --- messages resource

get-messages: function [
	room
	/with "skip, beforeId, afterId, aroundId, limit, q (search query)"
		values
] [
	data: copy [%rooms room %chatMessages]
	if with [append data compose [? (values)]]
	send-gitter data
]

get-message: function [
	room
	id
] [
	send-gitter [%rooms room %chatMessages id]
]

send-message: function [
	room
	text
] [
	send-gitter/post [%rooms room %chatMessages] json-map [text: text]
]

update-message: function [
	room
	text
	id
] [
	send-gitter/post [%rooms room %chatMessages id] json-map [text: text]
]

; --- user resource

user-info: does [first send-gitter %user]

list-unread: function [
	user
	room
] [
	send-gitter [%user user %rooms room %unreadItems]
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
	send-gitter/post [%user user %rooms room %unreadItems] rejoin [{^{"chat":[} messages {]^}}]
]

list-orgs: function [
	user
] [
	send-gitter [%user user %orgs]
]

list-repos: function [
	user
] [
	send-gitter [%user user %repos]
]

list-channels: function [
	user
] [
	; TODO
]