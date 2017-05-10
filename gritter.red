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

print*: :print

print-log: {}
log?: false

print: func [value /local line] [
	if log? [
		line: head append form reduce value newline
		append print-log line
		write %log.log print-log
		print* value
	]
]

keep-all: function [
	'word
	series
	body
] [
	collect [
		foreach :word series [
			do bind body :word
		]
	]
]

match: function [
	"Match value in block"
	series
	value
] [
	collect [
		foreach item series [
			if equal? value copy/part item length? value [keep item]
		]
	]
]

; ----------------------------------------------------------------------------
;		initialization
; ----------------------------------------------------------------------------

do %gitter-api.red
do %gitter-tools.red
do %rich-text.red
do %lest.red
do %marky-mark.red

system/view/auto-sync?: false

either exists? %options.red [
	do load %options.red
] [
	token: ask "Please, type your Gitter token (you can get one at https://developer.gitter.im/apps): "
]

select-by: func [
	series
	key
	value
] [
	foreach item series [
	;	print [value key item]
		if equal? value select item key [return item]
	]
	none
]


; ----------------------------------------------------------------------------
;		support
; ----------------------------------------------------------------------------

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
	info: none
	user-id: none
	room: none
	room-id: none
	room-ids: none
	rooms: none
	data-rooms: none
	data-chat: none
	messages: none
	unread: copy []
	text-boxes: #()
	avatars: #()

	chat-rooms: copy [] ; multi user rooms
	user-rooms: copy [] ; one to one rooms

	data-chat-rooms: none
	data-user-rooms: none

	sort-by-name: func ["Comparator for SORT" a b] [a/name < b/name]

	init: func [
		/local chat
	] [
		view/no-wait main-lay
		info: gitter/user-info
		user-id: info/id

		; setup room lists
		rooms: gitter/user-rooms user-id
		clear chat-rooms ; multi user rooms
		clear user-rooms ; one to one rooms
		foreach room rooms [
			append either room/oneToOne [user-rooms] [chat-rooms] room
		]
		sort/compare user-rooms :sort-by-name
		sort/compare chat-rooms :sort-by-name
		data-chat-rooms: collect [foreach room chat-rooms [keep room/name]]
		data-user-rooms: collect [foreach room user-rooms [keep room/name]]

		list-rooms/data: data-chat-rooms
		list-users/data: data-user-rooms
		room-topic/flags: [Direct2D]

		show main-lay

		; FIXME: ROOM here is leaked from FOREACH ROOM ROOMS [...] above
		;		I would like to use different room, but it crashes
		;		only this leaked value does not lead to crash
		room-id: rooms/1/id
		select-room room/name ; TODO: remember last selection

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

	refresh: function [
		"Refresh list-chat"
		face
		/force
		/extern unread
	] [
		print "refresh"
		unread: gitter/list-unread user-id room-id
		if any [
			force
			all [
				not empty? unread/chat
				not empty? not-shown face/pane unread
				not equal? unread/chat not-shown face/pane unread
			]
		] [
			print "refresh required"
			messages: gitter/get-messages room-id
			face/pane: layout/tight/only show-messages messages
			face/pane/1/offset/y: face/size/y - face/pane/1/size/y
			print "refresh > show"
			show face
		] 
	]
	
	send-message: does [
		"Send content of input area to selected channel/user"
		unless empty? area-input/text [
			gitter/send-message room-id area-input/text
			clear area-input/text
			show area-input
			refresh/force list-chat
		]
	]

	; FIXME: layout leaks face names (i.e.: list-rooms)

	; --- LAYOUTS

	idle-lay: layout/only [
		text "Loading room..."
	]

; >> 600x370 - 94x24 / 2
; == 253x173
	
	idle-lay/1/offset: 253x173 ; TODO: not hardcoded


	main-lay: layout [
		title "Gritter - A Red Gitter Client"
		style scroller: image 12x370 draw []
			on-create [
				face/data: 0%
				face/extra: object [
					drag?:	no
					ratio: 30% 			; relative knob size
					offset: 3.0 		; knob offset from border
					drag-start: 0
					knob-pos: offset	; absolute knob start
					knob-size: 0 		; absolute knob size

					outer-outline: 		220.220.220
					outer-fill: 		'off
					inner-outline: 		220.220.220
					inner-fill-away: 	160.160.160
					inner-fill-over: 	120.120.120
					inner-fill:			inner-fill-away

					fade-in?: 			true

					process-event: function [face event] [
						area-size: face/size/y - face/extra/offset
						face/extra/knob-pos: max face/extra/offset min area-size * (100% - face/extra/ratio) event/offset/y - face/extra/drag-start
						face/data: min 100% to percent! (face/extra/knob-pos - face/extra/offset) / (area-size - (area-size * face/extra/ratio) - face/extra/offset)
					]

					redraw: function [face] [
						if all [
							face/parent
							prev-face: find face/parent/pane face
						] [
							prev-face: first back prev-face
							unless equal? prev-face/size/y face/size/y [
								face/size/y: prev-face/size/y
								show face
							]
						]
						; compute knob position and size from DATA and RATIO values
						area-size: face/size/y - (2 * face/extra/offset)
						face/extra/knob-size: to integer! area-size * face/extra/ratio
						face/extra/knob-pos: to integer! area-size - face/extra/knob-size * face/data + face/extra/offset
						; draw scroller
						face/draw: compose [
							; area
							pen (face/extra/outer-outline)
							fill-pen (face/extra/outer-fill)
							box 0x0 (face/size - 1x1) 3
							; knob
							pen (face/extra/inner-outline)
							fill-pen (face/extra/inner-fill)
							box 
								(as-pair face/extra/offset - 1 face/extra/knob-pos) 
								(as-pair face/size/x - face/extra/offset face/extra/knob-pos + face/extra/knob-size)
								3
						]
					]
				]
				face/flags: [all-over]
				face/extra/redraw face
			]

			on-down [
				face/extra/drag-start: event/offset/y - face/extra/knob-pos
				face/extra/drag?: yes
			]

			on-up [
				face/extra/drag?: no
			]		
			on-over [
		;		print ["on-over detected" event/away?]
		; anim
				face/extra/fade-in?: not event/away?
				; TODO: prevent fade when fully faded on over
				face/rate: 30
				show face

		; drag
				if face/extra/drag? [
					face/extra/process-event face event
					face/extra/redraw face
					prev-face: first back find face/parent/pane face
					prev-face/pane/1/offset/y: to integer! face/data * (prev-face/size/y - prev-face/pane/1/size/y)
					show reduce [face prev-face]
				]
			]
			on-time [
				step: 30.30.30
				action: none
				condition: none
				set [action condition] either face/extra/fade-in? [
					[- [<= face/extra/inner-fill-over]]
				] [
					[+ [>= face/extra/inner-fill-away]]
				]
				do compose/deep [
					face/extra/inner-fill: face/extra/inner-fill (action) step
					if face/extra/inner-fill (condition) [
						face/extra/inner-fill: (second condition)
						rate: none
					]
				]
				face/extra/redraw face
				show face
			]

		panel 220x450 [
			below
			group-box 210x210 "Rooms" [
				below
				base 0x3
				list-rooms: text-list 190x200 data data-chat-rooms [
					print "click in list-rooms"
					list-users/selected: none
					select-room pick face/data face/selected
				]
			]
			group-box 210x210 "Users" [
				below
				base 0x3
				list-users: text-list 190x200 data data-user-rooms [
					print "click in list-users"
					list-rooms/selected: none
					select-room pick face/data face/selected
				]
			]
		]
		panel [
			room-icon: image 50x50
			room-topic: base 550x50 240.240.240 extra #()
			return
			list-chat: panel white 600x370 [] rate 1 ; now 
				on-time [
				;	print [now/time "calling list-chat on-time"]
					refresh face
				] 
			scroller
		]
		return
		text 220 "Search:" right
		field 500 [
			probe face/text
		]
		return
		area-input: area 680x100 extra #(match-string: #[none] matches: #[none])
			on-key [
				probe reduce ["onkey" mold event/key]

				case/all [
					all [equal? #"^/" event/key event/ctrl?] [
						send-message
					]
					equal? event/key #"^-" [
						probe "TAB pressed"
						; first tab press
						unless probe face/extra/match-string [
							probe "no match-string"
							face/extra/match-string: probe next find/last face/text #"@"
							probe room/userCount
						]
						; TODO: move this outside, should be cached
						users: sort gitter/get-users room
						users: collect [
							foreach user users [
								keep user/username
							]
						]
						probe users
						; ---
						face/extra/matches: probe match users face/extra/match-string
						either 1 = length? probe face/extra/matches [
							; only one match, autocollect
							change face/extra/match-string first face/extra/matches
							probe face/text
							show face
							face/extra/match-string: none
							probe words-of face
							return 'stop
						] [
							; more matches, rotate
						]
					]
				]



			]
		button "Send" [send-message]
		button "Info" [
			pane-height: 0
			foreach face list-chat/pane [pane-height: pane-height + face/size/y]
			print mold reduce [list-chat/size length? list-chat/pane pane-height]
		]
	;	return
	;	text "room info"
	;	room-info: base 200x80 200.240.200
	]

	; GUI support funcs

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
			extend avatars reduce [message/fromUser/username load to url! message/fromUser/avatarUrlSmall]
		]
		; color: average-color avatars/:name
		size: either height < 50 [30x30] [50x50]
		compose [
			image (get avatar-path) (size) extra (name) [face/extra]
		]
	]

	actors: context [
		; locals
		start:
		length:
		text-box:
		index:
		style: none

		; actors
		get-style: [
			text-box: face/draw/3 ; draw/3 is text-box
			index: text-box/index? event/offset
			styles: probe text-box/styles
			condition: [
				if (all [index >= start index < (start + length)]) (
					print [index start length style]
					print text-box/links
				) 
				to end
			]

			parse styles [
				some [
					set start integer!
					set length integer!
					copy style some [
						'bold | 'italic | 'underline
					|	'font-size skip | 'font-name skip
					]
					opt condition
				]
			]
		]
		get-link: func [face event] [
			text-box: face/draw/3 ; draw/3 is text-box
			index: text-box/index? event/offset
			foreach [start length link] text-box/links [
				if all [index >= start index < (start + length)] [
					return link
				]
			]
		]
	]

	draw-body: function [
		message
		body
		backdrop
	] [
		text-box: none
		index: none
		name: to word! rejoin ["msg-" message/id]
		out: compose/deep [
			(to set-word! name) base (backdrop) 530x100
				draw [text 0x0 (body)] 
				extra (make object! [
					id: message/id
				])
				on-up [browse actors/get-link face event]
			;	on-over [actors/get-link]
			do [(make set-path! reduce [name 'flags]) [Direct2D all-over]]
		]
		body/target: name
		body/layout
		out/4/y: body/height ; 4 is SIZE in draw block (see above)
		out
	]

	draw-room-info: function [
		room
	] [
	;	probe room
		styles: []
		text: room/name
		make text-box! copy/deep compose/deep [
			text: (text)
			styles: [(styles)] 
		;	size: (as-pair x-size 300) ; TODO: how to get max Y-SIZE ?
		]
		room/name
	]

	get-room-id: func [
		"Return room-id from selection in list"
		rooms
		face
	] [
		room: pick face/data face/selected
		room: select-by rooms 'name value
		room/id
	]

	select-room: func [
		name "Room name"
		/local value topic info
	] [
		print ["select-room" name]

		list-chat/pane: idle-lay
		show list-chat 

		room: select-by rooms 'name name
		if equal? #"/" first room/url [remove room/url]
		room: gitter/get-room room/url
		print mold room
		room-id: room/id
		main-lay/text: rejoin ["Gritter: " value]

		print "before image loading"

		room-icon/image: if room/avatarUrl [
			load to url! room/avatarUrl ; TODO: cache room avatars (icons)
		]

		print "after image loading"

		name: make text-box! [size: 500x40 text: room/name font: fonts/room-name]

		print "before layout"
		unless name/text [name/text: "WARNING: No name present"]
		print mold name

		name/layout

		print "after layout"

	;	print ["name width: " name/width] 
		topic: make text-box! [size: as-pair 500 - name/width 40 text: room/topic]

		print "make info-text"

		info-text: rejoin [
			either room/oneToOne [""] [rejoin ["Users: " room/userCount]]
			either empty? room/tags [""] [rejoin [", Tags: " room/tags]] ; TODO: clickable tags
		]

		print ["info-text:" mold info-text]
		info: make text-box! [
			size: 250x20 
			font: fonts/name
			text: info-text
		] 

		print "compose"
		room-topic/draw: compose [
			text 0x0 (name) 
			text (as-pair 10 + name/width 0) (topic)
			text 10x33 (info)
		]

		print "show topic"
		show room-topic

	;	room-info/draw: compose [text 0x0 (draw-room-info room)]
	;	show room-info

		print "show main-lay"
		show main-lay

		print "call refresh force"
		refresh/force list-chat
	]

	show-messages: function [
		messages
		/extern unread
	] [
		print "show messages"
		out: copy []
		foreach message messages [

		;	if code: get-code message [probe code]

			id: message/id
			backdrop: either new?: to logic! find unread/chat id [200.250.200] [240.240.240]
			body: emit-text-box marky-mark message/text
			text-boxes/:id: body ; TODO: is it required?
			body: draw-body message body 240.240.240 ; pre-render body, so we can get height for avatar
			height: body/4/y 
			append out compose/deep [
				base (backdrop) 600x20 draw [(draw-header message)] extra (new?) ; rate 1 on-time [if probe face/extra [print "new message says hello!"]]
				return
				(draw-avatar message height)
				space 5x0
				(body)
				return
			]
		]
		print "show messages after loop"
		out: compose/deep [across space 0x0 panel (240.240.240) [(out)]]
	;	print mold out
		out
	]

]

; ---

make-fonts [
	name: 9 30.30.30 #bold
	username: 8 100.100.100 #bold
	room-name: 18 100.100.100 #bold
]

para: make para! [wrap: on]

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


; --------------

gritter/init

if not exists? %options.red [					;-- No need to save every time, token does not change often
	save %options.red compose [token: (token)]
]
