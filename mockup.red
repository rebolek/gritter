Red[]

win: layout [


	backdrop 54.57.62

	style circle: base 20x20 on-create [
		face/extra: context [
			pen: face/color
			bright-pen: face/color * 1.5
		]
		face/draw: compose [
			pen off 
			fill-pen (face/extra/pen) 
			circle (face/size / 2) (face/size/x / 2 - 2)
		]
		face/color: none
	] on-over [
		face/draw/4: pick reduce [face/extra/pen face/extra/bright-pen] event/away?
	]

	style hamburger: base 20x20 draw [
		line-width 2
		pen white
		line 3x5 17x5
		line 3x10 17x10
		line 3x15 17x15
	] on-create [
		face/color: none
	]

	style bar: base 300x1 on-create [
		face/extra: context [
			pen: face/color
		]
		face/draw: compose [
			pen (face/extra/pen) 
			line 0x0 (as-pair face/size/x 0)
		]
		face/color: none
	]

	style shadow-bar: base 300x3 on-create [
		face/extra: context [
			pen: face/color
		]
		face/draw: compose [
			pen (face/extra/pen) 
			line 0x0 (as-pair face/size/x 0)
			pen (face/extra/pen + 15)
			line 0x1 (as-pair face/size/x 1)
			line 0x2 (as-pair face/size/x 2)
		]
		face/color: none
	]

	style draw-field: base 280x50 on-create [
		face/color: none
		face/draw: probe compose [
			pen 218.221.223
			line-width 2
			box 2x2 (face/size - 2) 
			translate 5x5 [
				pen 116.127.141
				line 15x28 10x28
				line 10x28 10x10
				line 10x10 30x10
				line 30x10 30x28
				line 30x28 25x28
				line 20x32 20x17
				line 15x23 20x17
				line 20x17 25x23
			]
			text 50x5 "Chat in general..."
		]
	]

	style avatar: base 50x50 on-create [
		print type? face/image
		face/extra: context [
			image: face/image
			redraw: func [face][
				face/draw: compose [
					pen off
					fill-pen bitmap image 0x0 64x64
					circle (face/size / 2) (face/size/x / 2 - 2)
				]
			]
		]
		face/image: none
		face/color: none
		face/extra/redraw face
	]

	style scroller: base 20x200 on-create [
		face/color: none
		face/extra: context [
			offset: 2
			start: 20
			height: 50
			radius: face/size/x / 2 - offset
			redraw: func [face][
				face/draw: probe compose/deep [
					pen white
					fill-pen 218.221.223
					shape [
						move (as-pair offset radius + offset)
						arc (as-pair face/size/x - offset - 1 radius + offset) (radius) (radius) 0 sweep
						vline (face/size/y - radius - offset - 1)
						arc (as-pair offset face/size/y - radius - offset - 1) (radius) (radius) 0 sweep
					]
					line-width 3
					pen white
					fill-pen 116.127.141
					shape [
						move (as-pair offset radius + start)
						arc (as-pair face/size/x - offset - 1 radius + start) (radius) (radius) 0 sweep
						vline (start + height)
						arc (as-pair offset start + height) (radius) (radius) 0 sweep
					]
				]
			]
		]
		face/extra/redraw face
	]

; ------------------------------------------------------------------------- ;

	space 0x0

	panel 100x300 40.43.48 [
		circle 187.80.77
		circle 188.145.59
		circle 47.152.65
		return 
		circle 10x10 187.80.77
		circle 15x15 188.145.59
		circle 18x18 47.152.65
		return
		a: avatar %avatar1.png 50x50	
	]
	panel 200x300 54.57.62 [
		below
		at 180x5 hamburger
		at 0x30 bar 49.52.56
	]
	panel 300x300 white [
		at 0x30 shadow-bar 236.236.236
		at 10x240 draw-field 280x50
		at 280x35 scroller 15x200

	]
]


view win
