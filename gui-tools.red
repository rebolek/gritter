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
