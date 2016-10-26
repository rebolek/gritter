Red [
	Title: "Gritter - Red Gitter client"
	Author: "Boleslav Březovský"
	File: %gritter.red
	Rights: "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
	}
	Date: "23-10-2016"
	Note: {
	}
]

; ----------------------------------------------------------------------------
;		initialization
; ----------------------------------------------------------------------------

do %gitter-api.red
do %rich-text.red
do %marky-mark.red

system/view/auto-sync?: false

; ----------------------------------------------------------------------------
;		support
; ----------------------------------------------------------------------------

either exists? %options.red [
	do %options.red
] [
	token: to issue! ask "Please, type your Gitter token (you can get one at https://developer.gitter.im/apps):"
]

inside-face?: function [
	face
	point
] [
	all [
		point/x >= face/offset/x
		point/x <= (face/offset/x + face/size/x)
		point/y >= face/offset/y
		point/y <= (face/offset/y + face/size/y)
	]
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
;		GUI
; ----------------------------------------------------------------------------


gritter: context [
	; TODO: token here?
	info: user-info
	user-id: info/id

	last-select: 0
	room-ids: none
	data-rooms: none
	room-1-1-ids: none
	data-1-1-rooms: none
	data-chat: none
	room-id: func [
	][
		either last-select = 0 [
			if all [room-ids list-rooms/selected] [pick room-ids list-rooms/selected]
		][
			if all [room-1-1-ids list-1-1-rooms/selected] [pick room-1-1-ids list-1-1-rooms/selected]
		]
	]
	
	init: func [
		/local rooms chat
	] [
		rooms: user-rooms user-id
		;probe rooms
		data-rooms: collect [
			foreach room rooms [if room/githubType <> "ONETOONE" [keep room/name]]
		]
		data-1-1-rooms: collect [
			foreach room rooms [if room/githubType = "ONETOONE" [keep rejoin [room/user/username " - " room/name]]]
		]
		room-ids: collect [
			foreach room rooms [if room/githubType <> "ONETOONE" [keep room/id]]
		]
		room-1-1-ids: collect [
			foreach room rooms [if room/githubType = "ONETOONE" [keep room/id]]
		]
		list-rooms/data: data-rooms
		list-rooms/selected: 1 ; TODO: remember last selection
		list-1-1-rooms/data: data-1-1-rooms
		list-1-1-rooms/selected: 1 ; TODO: remember last selection

		messages: get-messages room-id
		list-chat/pane: layout/tight/only show-messages messages
		view main-lay
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
;					probe reduce [face/size face/extra]
					found?: found? or equal? message face/extra
				]
				unless found? [keep message]
			]
		]
	]

	refresh: function [
		"Refresh list-chat"
		face
		one-to-one
		/force
		/local local-room-id
	] [
;		prin ["get unread..."]
		local-room-id: room-id

		unread: list-unread user-id local-room-id
;		print ["done." force unread/chat not-shown face/pane unread]
		if any [
			force
			all [
				not empty? unread/chat
				not empty? not-shown face/pane unread
				not equal? unread/chat not-shown face/pane unread
			]
		] [
;			print "refresh required"
			messages: get-messages local-room-id
			face/pane: layout/tight/only show-messages messages
			face/pane/1/offset/y: face/size/y - face/pane/1/size/y
			show face
		] 
	]

	main-lay: layout [
		style scroller: image 12x370 draw []
			on-create [
				face/extra: object [
					drag?:	no
					ratio: 30%
					offset: 3.0
					knob-start: 0				
					knob-pos: offset

					outer-outline: 220.220.220
					outer-fill: 'off
					inner-outline: 220.220.220
					inner-fill: 160.160.160

					set-data: function [face event] [
						area-size: face/size/y - face/extra/offset
						face/extra/knob-pos: max offset min area-size * (100% - face/extra/ratio) event/offset/y - face/extra/knob-start
						face/data: min 100% to percent! (face/extra/knob-pos - face/extra/offset) / (area-size - (area-size * face/extra/ratio) - face/extra/offset)
					]

					redraw: function [face] [
						face/draw: compose [
							pen (face/extra/outer-outline)
							fill-pen (face/extra/outer-fill)
							box 0x0 (face/size - 1x1) 3
							pen (face/extra/inner-outline)
							fill-pen (face/extra/inner-fill)
							box (as-pair face/extra/offset - 1 face/extra/knob-pos) (as-pair face/size/x - face/extra/offset face/size/y - face/extra/offset * face/extra/ratio + face/extra/knob-pos) 3
						]
					]
				]
				face/flags: [all-over]
				face/extra/redraw face
			]

			on-down [
			;	print ["on-down" face/extra/knob-start event/offset/y]
				face/extra/knob-start: event/offset/y - face/extra/knob-pos
				face/extra/drag?: yes
			]

			on-up [
			;	print "on-up"
				face/extra/drag?: no
			]		
			on-over [
				if face/extra/drag? [
					face/extra/set-data face event
					face/extra/redraw face
					prev-face: first back find face/parent/pane face
					prev-face/pane/1/offset/y: to integer! face/data * (prev-face/size/y - prev-face/pane/1/size/y)
					show reduce [face prev-face]
				]
			]

		group-box 220x370 "Rooms" [
			list-rooms: text-list 200x350 extra 0 data data-rooms [
				last-select: 0
				refresh/force list-chat last-select
			]
		]
		group-box 220x370 "One to One Rooms" [
			list-1-1-rooms: text-list 200x350 extra 1 data data-1-1-rooms [
				last-select: 1
				refresh/force list-chat last-select
			]
		]
		list-chat: panel white 600x370 [] rate 1 now 
			on-time [
				refresh face last-select
			] 
		scroller
		return
		area-input: area 580x100 ; [probe face/text]
		button "Send" [
			unless empty? area-input/text [
				send-message room-id area-input/text
				clear area-input/text
				show area-input
				refresh/force list-chat
			]
		]
		button "Info" [
			pane-height: 0
			foreach face list-chat/pane [pane-height: pane-height + face/size/y]
			print mold reduce [list-chat/size length? list-chat/pane pane-height]
		]
	]
]

; ---

make-fonts [
	name: 9 30.30.30 #bold
	username: 8 100.100.100 #bold
]

para: make para! [wrap: on]

avatars: copy []

check-over: function [
	face
	event-offset
] [
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
			if inside-face? area event-offset [
			;	print ["inbside:" area]
				pos: find face/draw area/offset
				if pos [
					pos: back back pos
					if equal? fonts/link first pos [
						face/extra/highlight: copy area
						pos/1: fonts/active-link
						show face
					]
				]
			]		
		]
	] 
]

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
		base 240.240.240 (body/2) 
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
		]
]

show-messages: function [
	messages
] [
	out: copy []
	foreach message messages [
		body: rich-text/info emit-rich marky-mark message/text 530
		append out compose/deep [
			base 240.240.240 600x20 draw [(draw-header message)]
			return
			(draw-avatar message body/2/y)
			space 5x0
			(draw-body message body)
			return
		]
	]
	compose/deep [across space 0x0 panel 240.240.240 [(out)]]
]


; --------------

gritter/init

if not exists? %options.red [
	save %options.red compose [token: (token)]
]
