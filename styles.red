Red []

scroller: image 12x370 draw []
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