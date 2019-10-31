Red[
	Title: "Support GUI functions for Gritter"
	Author: "Boleslav Březovský"
	File: %gui-tools.red
	Rights: "Copyright (C) 2019 Boleslav Březovský. All rights reserved."
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

; --- fonts -----------------------------------------------------------------

make-fonts: function [
	spec
] [
	font: none
	styles: clear []
	parse spec [
		some [
			set font set-word! (
				clear styles
				parent: fonts/base
				name: parent/name
				size: parent/size
				color: parent/color
				parent: 'base
			)
			opt [set parent word!]
			any [
				set name string!
			|	set size integer!
			|	set color tuple!
			|	set style issue! (append styles load form style)	
			]
			(
				fonts/:font: make fonts/:parent compose/deep [
					name: (name)
					size: (size)
					color: (color)
					style: [(styles)]
				]
			)
		]
	]
]

fonts: #()

fonts/base: make font! [
	name: "Segoe UI"
	size: 10
	color: 30.30.30
	style: []
	anti-alias?: yes
]

make-fonts [
	text: base 10
	bold: #bold
	italic: #italic
	underline: #underline
	link: #bold 120.60.60
	active-link: #bold 220.160.160
	fixed: "Lucida Console"
	name: 9 30.30.30 #bold
	username: 8 100.100.100 #bold
]
