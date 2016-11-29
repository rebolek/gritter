Red [
	Title: "Gritter - Red Gitter client"
	Author: "Boleslav Březovský"
	File: %gritter.red
	Rights: "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
	}
	Date: "7-11-2016"
	Note: {
	}
]

; ----------------------------------------------------------------------------
;		initialization
; ----------------------------------------------------------------------------

do %fonts.red
do %gitter-api.red
do %rich-text.red
do %marky-mark.red
do %lest.red

system/view/auto-sync?: false

; ----------------------------------------------------------------------------
;		support
; ----------------------------------------------------------------------------

either exists? %options.red [
	do %options.red
] [
	token: to issue! ask "Please, type your Gitter token (you can get one at https://developer.gitter.im/apps):"
]

average-color: function [
	image
] [
	color: copy [r 0 g 0 b 0]
	foreach pixel image [
		color/r: color/r + pixel/1
		color/g: color/g + pixel/2
		color/b: color/b + pixel/3
	]
	clr: 0.0.0
	clr/1: color/r / (length? image)
	clr/2: color/g / (length? image)
	clr/3: color/b / (length? image)
	clr
]

unless value? 'rejoin [
	rejoin: func [
		"Reduces and joins a block of values." 
		block [block!] "Values to reduce and join"
	] [
		if empty? block: reduce block [return block] 
		append either series? first block [
			copy first block
		] [
			form first block
		] 
		next block
	]
]

; ----------------------------------------------------------------------------
; 		ANIMATE subsystem
; ----------------------------------------------------------------------------

animate: function [
	value ; action
] [
	rate: 30 ;  should be probably user-definable
	anims: []		; block of running animations
	actions: #(
		fade: context [
			init: function [action] [
				; TODO: compute step and append it
				; args: [face word target-value]
				args: skip action 2
				start: get in args/1 args/2
				append args args/3 - start / action/1
				action
			]
			run: function [args] [
				; face: args/1 word: args/2 step: args/3
				value: get in args/1 args/2
				set in args/1 args/2 value + args/3
			]
			stop: function [args] [
				; final-value: args/4
				set in args/1 args/2	
			]
		]
	)
	; register new action when necessary
	if value [
		if integer? value/1 [
			; value is in miliseconds
			value/1: value/1 * 1.0 / 1000 + 0:0:0
		]
		append anims actions/(value/2)/init value
	]
	; process actions
	foreach anim anims [
		probe anim
	]
	anims
]

; ----------------------------------------------------------------------------
;		GUI
; ----------------------------------------------------------------------------


colors: context [
;	background: 253.246.227 ; light
	background: 0.43.54 	; dark
]

gritter: context [
	; faces
	list-chat: none
	list-rooms: none
	area-input: none
	scroller-chat: none
	buttons: none

	; other values
	; TODO: token here?
	info: user-info
	user-id: info/id
	room-ids: none
	data-rooms: none
	data-chat: none
	messages: none 		; messages cache
	room-id: func [] [if all [room-ids list-rooms/selected] [pick room-ids list-rooms/selected]]

	init: func [
		/local rooms chat
	] [
		rooms: user-rooms user-id
		data-rooms: collect [
			foreach room rooms [keep room/name]
		]
		room-ids: collect [
			foreach room rooms [keep room/id]
		]
		list-rooms/data: data-rooms
		list-rooms/selected: 1 ; TODO: remember last selection

		view/no-wait/flags gui [resize]

		scroller-chat/data: 100%		
		refresh/force list-chat ; FIXME: no messages on first view
		
		; patch GUI for resizing

		gui/extra: object [
			old-size: gui/size
		]

		gui/actors: object [
			on-resizing: func [face [object!] event [event!] /local delta][
				delta: face/size - face/extra/old-size
				
				list-chat/size: list-chat/size + delta
				
				scroller-chat/offset/x: scroller-chat/offset/x + delta/x
				scroller-chat/size/y: scroller-chat/size/y + delta/y
				scroller-chat/extra/redraw scroller-chat

				area-input/offset/y: area-input/offset/y + delta/y
				area-input/size/x: area-input/size/x + delta/x
				
				buttons/offset: buttons/offset + delta/y
				buttons/size/x: buttons/size/x + delta/x
				
				refresh/only list-chat
				show [list-chat scroller-chat area-input buttons]
				face/extra/old-size: face/size
			]
		]

		do-events

	]

	not-shown: function [
		pane
		unread
	] [
		found?: false
		collect [
			foreach message unread/chat [
				found?: false
				foreach face pane/1/pane [
					found?: found? or equal? message face/extra
				]
				unless found? [keep message]
			]
		]
	]

	refresh: function [
		"Refresh list-chat"
		face
		/only 	"Refresh only and do not check for new messages"
		/force 	"Force refresh even if there are no new messages"
		/extern messages
	] [
		print ["refresh" now/time/precise]
		unless only [unread: list-unread user-id room-id]
		if any [
			only
			force
			all [
				not empty? unread/chat
				not empty? not-shown face/pane unread
				not equal? unread/chat not-shown face/pane unread
			]
		] [
			unless only [messages: get-messages room-id]
			face/pane: layout/tight/only show-messages/width messages face/size/x - 70
			face/pane/1/offset/y: to integer! face/size/y - face/pane/1/size/y * scroller-chat/data
;			scroller-chat/data: 100%
			; update scroller bar size
			ratio: to percent! face/size/y * 1.0 / face/pane/1/size/y
			unless equal? ratio scroller-chat/extra/ratio [
				scroller-chat/extra/ratio: ratio
				scroller-chat/extra/redraw scroller-chat
				show scroller-chat
			]
			show [face scroller-chat]
		] 
	]

	check-over: function [
		face
		event-offset
	] [
		; TODO: rewrite using 'check-up code
		areas: face/extra/areas
		either face/extra/highlight [
			unless inside-face? face/extra/highlight event-offset [
				if pos: find face/draw fonts/active-link [
					pos/1: fonts/link
					face/extra/highlight: none
					show face
				]
			]
		] [
			foreach area areas [
				if all [
					equal? 'link area/type
					inside-face? area event-offset
				] [
					pos: find face/draw area/offset
					if pos [
						pos: back back pos
						face/extra/highlight: area
						pos/1: fonts/active-link
						show face
					]
					break
				]
			]
		] 
	]

	check-up: function [
		face
		event-offset
	] [
		foreach area face/extra/areas [
			all [
				equal? 'link area/type
				inside-face? area event-offset
				browse area/link
				break
			]
		]
	]

; -- draw message

	draw-header: function [
		message
	] [
		f: make face! [
			font: fonts/name
		]
		name-size: size-text/with f message/fromUser/displayName

		msg: compose [
			font (fonts/name)
			text 0x0 (message/fromUser/displayName)
			font (fonts/username)
			text (as-pair name-size/x + 5 2) (rejoin [#"@" message/fromUser/username " <" message/sent ">"])
		]
	]

	draw-avatar: function [
		message
		height
	] [
		avatar-path: 'avatars/username
		avatar-path/2: to word! message/fromUser/username
		name: to word! message/fromUser/username
		unless avatars/:name [
			repend avatars [to word! message/fromUser/username load to url! message/fromUser/avatarUrlSmall]
		]
		color: average-color avatars/:name
		size: either height < 50 [30x30] [50x50]
		compose [
		;	base (probe as-pair 50 - size/x / 5 0) transparent
		;	image (get avatar-path) (size)
			base (size) (color)
		;	base (probe as-pair 50 - size/x / 2 0) transparent
		]
	]

	draw-body: function [
		message
		body
	] [
		compose/deep [
			base (colors/background) (body/2) 
				draw [(body/1)] 
				extra (make object! [
					id: message/id
					areas: body/3
					highlight: none
				])
				on-create [
					face/flags: [all-over]
				]
				on-over [
					; having check-over here directly crashes Red
					check-over face event/offset
				]
				on-up [
					check-up face event/offset
				]
			]
	]

	show-messages: function [
		"Generate VID block of messages"
		messages 	[block!]	"Messages to show"
		/width					"Use custom width"
			size 				"Custom width value"
		/extern colors
	] [
		unless width [size: 530]
		out: copy []
		foreach message messages [
			body: rich-text/info lest marky-mark message/text size
			append out compose/deep [
				base (colors/background) 600x20 draw [(draw-header message)]
				return
				(draw-avatar message body/2/y)
				space 5x0
				(draw-body message body)
				return
			]
		]
		compose/deep [across space 0x0 panel (colors/background) [(out)]]
	]

	css: stylize load %styles.red

	actions: object [
		select-room: does [
			list-rooms: text-list 200x350 data data-rooms [
				refresh/force list-chat
			]
		]
		send-message: does [
			unless empty? area-input/text [
				send-message room-id area-input/text
				clear area-input/text
				show area-input
				refresh/force list-chat
			]
		]
		show-info: does [			
			pane-height: 0
			foreach face list-chat/pane [pane-height: pane-height + face/size/y]
			print mold reduce [list-chat/size length? list-chat/pane pane-height]
		]
	]

	gui: layout [
		styles css
		group-box 220x370 "Rooms" [
			; FIXME: why I can’t use select-room here?
			list-rooms: text-list 200x350 data data-rooms [
				refresh/force list-chat
			]
		]
		list-chat: panel white 600x370 [] rate 1 now 
			on-time [refresh face] 
		scroller-chat: scroller
		return
		area-input: area 760x100
		buttons: panel [
			below
			button "Send" [actions/send-message]
			button "Info" [actions/show-info]
		]
	] 
]

; ---

; light
make-fonts [
	name: 9 147.161.161 #bold
	username: 8 131.148.150 #bold
]
; dark
make-fonts [
	name: 9 88.110.117 #bold
	username: 8 101.123.131 #bold
]


avatars: copy []


; --------------

gritter/init

save %options.red compose [token: (token)]
