Red [
	Title: "Gritter - Red Gitter client"
	Author: "Boleslav Březovský"
	File: %gritter.red
	Rights: "Copyright (C) 2016-2019 Boleslav Březovský. All rights reserved."
	License: 'BSD
	Date: "23-10-2016"
	Needs: 'View
	Note: {
	}
]

; ----------------------------------------------------------------------------
;		initialization
; ----------------------------------------------------------------------------

#include %gitter-api.red
#include %rich-text.red
#include %marky-mark.red
#include %gui-tools.red


system/view/auto-sync?: false

input-gitter-token: func [
	/local token f
][
	token: none
	view [
		below
		text 500 "Please, type your Gitter token^/(you can get one at https://developer.gitter.im/apps): "
		f: field 500
		button "Ok" [
			token: f/text
			unview
		]
	]
	token
]

gitter/token: either exists? %options.red [
	load %options.red
][
	input-gitter-token
]


; ----------------------------------------------------------------------------
;		GUI
; ----------------------------------------------------------------------------

gritter: context [
	user-info: none
	user-id: none
	data-chat: none
	rooms: #()
	room-info: none
	get-room-name: func [
	][
		either list-rooms/selected [
			pick list-rooms/data list-rooms/selected
		][
			first keys-of rooms
		]
	]
	get-room-id: func [][select rooms get-room-name]
	init: func [
		/local user-rooms chat names
	] [
		view/no-wait main-lay
		user-info: gitter/user-info
		user-id: user-info/id
		user-rooms: gitter/user-rooms user-id
		names: make map! []
		names/rooms: copy []
		names/users: copy []
		foreach room user-rooms [
			put rooms room/name room/id
			append either room/oneToOne [names/users][names/rooms] room/name
		]
		list-rooms/data: compose [(sort names/rooms) (sort names/users)]
		list-rooms/selected: 1 ; TODO: remember last selection
		show main-lay
		messages: gitter/get-messages get-room-id
		list-chat/pane: layout/tight/only show-messages messages
		show main-lay
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
;					probe reduce [face/size face/extra]
					found?: found? or equal? message face/extra
				]
				unless found? [keep message]
			]
		]
	]

	refresh: func [
		"Refresh list-chat"
		face
		/force
		/local unread messages
	] [
		unread: gitter/get-unread user-id get-room-id
		if any [
			force
			all [
				not empty? unread/chat
				not empty? not-shown face/pane unread
				not equal? unread/chat not-shown face/pane unread
			]
		] [
			print "refresh required"
			messages: gitter/get-messages get-room-id
			room-info: gitter/get-room-info get-room-name
			face/pane: layout/tight/only show-messages messages
			face/pane/1/offset/y: face/size/y - face/pane/1/size/y

			topic-info/draw: draw-room-info room-info

			show face
		] 
	]
	
	styles: [
		title "Gritter - A Red Gitter Client"
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
	]


	; FIXME: layout leaks face names (i.e.: list-rooms)

	main-lay: [
		group-box 220x370 "Rooms" [
			list-rooms: text-list 200x350 [
				refresh/force list-chat
			]
		]
		panel [
			across
			topic-info: base 240.240.240 600x60
			button-settings: base 240.240.240 30x30 "⚙" [
				print "TODO: Open settings"
			]
			return
			list-chat: panel white 600x370 [] rate 1 ; now 
				on-time [
					refresh face
				] 
			scroller
		]
		return
;		text 220 "Search:" right
		field 500 [
			probe face/text
		]
		return
		area-input: area 680x100 ; [probe face/text]
		below
		button "Send" [
			unless empty? area-input/text [
				gitter/send-message get-room-id area-input/text
				clear area-input/text
				show area-input
				refresh/force list-chat
			]
		]
		button "Refresh" [
				refresh/force list-chat
		]
		button "Info" [
			pane-height: 0
			foreach face list-chat/pane [pane-height: pane-height + face/size/y]
			print mold reduce [list-chat/size length? list-chat/pane pane-height]
		]
	]

	insert main-lay styles
	main-lay: layout main-lay

]

; ---

make-fonts [
	name: 9 30.30.30 #bold
	username: 8 100.100.100 #bold
]

colors: context [
	background: 240.240.240
]

para: make para! [wrap: on]

avatars: copy []

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
	avatar-path/2: message/fromUser/username
	name: message/fromUser/username
	unless avatars/:name [
		repend avatars [message/fromUser/username load to url! message/fromUser/avatarUrlSmall]
	]
	; color: average-color avatars/:name
	size: either height < 50 [30x30] [50x50]
	compose [
	;	base (probe as-pair 50 - size/x / 5 0) transparent
		image (get avatar-path) (size)
	;	base (size) (color)
	;	base (probe as-pair 50 - size/x / 2 0) transparent
	]
]

draw-body: function [
	message
	body
][
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
			on-up [
				check-up face event/offset
			]
		]
]

draw-room-info: func [
	info
][
	compose/deep [
;		base (colors/background) draw [
			font (fonts/name)
			text 4x4 (info/name)
			font (fonts/username)
			text 4x20 (info/topic)
			text 4x40 (mold info/tags)
;		]
	]
]

show-messages: function [
	messages
][
	out: copy []
	foreach message messages [
		body: rich-text/info emit-rich marky-mark message/text 530
		append out compose/deep [
			base (colors/background) 600x20 draw [(draw-header message)]
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
;-- No need to save every time, token does not change often
	save %options.red compose [token: (gitter/token)]
i]
