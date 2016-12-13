Red [
	Title: "Rich Text Dialect"
	Author: "Boleslav Březovský"
	File: %rich-text.red
	Rights: "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
	}
	Date: "2-12-2016"
	Note: {
		Rich Text Dialect takes Lest source and converts it to Draw dialect
		that can be supplied to Red/View.
	}
	To-Do: [
		"Fix height problem when code is first word on line"
	]
]

do %fonts.red

; -----------

whitespace?: function [
	char
] [
	find " ^/" char
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

; ----------------

rich-text: function [
	"Render Rich Text dialect to Draw block"
	dialect [block!]			"Rich Text Dialect input"
	with	[integer! object!]	"Face where to put Draw block in, or desired width"
	/info "Return object! with rendered data and metada also"
] [
	emit-text: func [/local text area] [
		unless empty? line [
			text: copy line
			append out reduce ['text as-pair start-pos pos/y text]
			area: make map! compose [
				type: (area-type)
				offset: (as-pair start-pos pos/y)
				size: (size-text/with face text)
				text: (text)
			]
			if equal? 'link area-type [
				area/link: take/last stack
			]
			append areas area
			append heights word-size/y
			blocks: blocks + 1
		]
	]

	fix-height: does [
		; --- place blocks on Y-axis
		out: tail out
		while [not zero? blocks] [
			if pair? out/1 [
				print mold out/2
				out/1/y: pos/y + line-height - heights/:blocks
				blocks: blocks - 1
			]
			out: back out
		]
		clear heights
		out: head out
		; ---
	]

	process-text: func [
		text
	] [
		start-pos: pos/x
		char-size: 0x0
;		print ["Process:" start-pos mold text]
		clear line
		clear word
		while [not tail? text] [
			; expand line
			char: first text
			; check cases
			case [
				; full word, needs check for wrapping
				any [
					whitespace? char
					tail? next text
				] (
					; append char if it’s not newline
					; newline will mess up word size
					unless equal? #"^/" char [append word char]
					size-word
					; check if we need to wrap
					if pos/x > (width - para/margin/x) do-wrap
					; append word to line
					append line copy word
					; newline wraps automatically
					if equal? newline char do-wrap
					clear word
					; if we are at the end of string, also emit line
					if tail? next text [
						emit-text
					;	fix-height
						clear line
					]
				)
				; tabulator is special case
				equal? #"^-" char (
					append word "    " 
				)
				; ordinary character
				true (append word char)
			]
			text: next text
		]
	]

	set-font: func [
		font
	] [
		repend out ['font font]
		face/font: font
	]

	init-para: func [/first] [
		fix-height
		pos/x: para/indent/x + para/origin/x
		pos/y: para/origin/y + pos/y + line-height + either first [0] [para/indent/y]
		line-height: 0
	]

	init-line: func [
		/blank "Add blank line"
	] [
		pos/x: para/origin/x
		start-pos: pos/x
		pos/y: pos/y + line-height
		if blank [pos/y + line-height]
		line-height: 0
		clear line
	]

	size-word: func [] [
	;	print "size-word"
		; FIXME: There is bug in Red, it sometimes ignores the font
		;		once the name is set again, it works as expected
		; NOTE: This bugfix throws some even stranger error:
		; *** Script Error: path none is not valid for none! type
		; *** Where: if
		; 	* but only in some cases. Hm
		face/font/name: copy face/font/name
		word-size: size-text/with face word
		; get position after the word
		pos/x: pos/x + word-size/x
		if word-size/y > line-height [line-height: word-size/y]
	]

	make-info: does [
		make object! compose/deep [
			data:	[(out)]
			size:	(as-pair width pos/y + line-height)
			areas:	[(areas)]
			over:	[]
			actors: context [
				on-over: function [
					face
					event
				] [
					either face/extra/highlight [
						unless inside-face? face/extra/highlight event/offset [
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
								inside-face? area event/offset
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
				on-up:	function [
					face
					event
				] [
					foreach area areas [
						all [
							equal? 'link area/type
							inside-face? area event/offset
							browse area/link
							break
						]
					]
				]
			]
		]
	]

	do-wrap: [
		; do wrapping - emit line and move to next line
		emit-text
		fix-height
		init-line
		size-word
	]

	; --- local vars

	out: make block! 2000
	font: none
	value: none
	stack: make block! 20
	start-pos: 0
	pos: 0x0
	blocks: 0
	line-height: 0
	line-spacing: 3 ; FIXME: Hardcoded height
	line: make string! 200
	word: make string! 50
	areas: make block! 50
	area-type: none

	para: context [
		indent: 5x0 ; Y-pos is not used right now
		origin: 5x5
		margin: 5x5
		tabs: none
	]

	heights: make block! 20

	face: make face! [
		font: fonts/text
	]

	; --- parse rules

	font-rule: [
		'font set value [word! | path!] 
		(set-font get value)
	]
	text-rule: [
		set value [string! | char!]
		(
		;	set-font fonts/text
			area-type: 'area
			process-text form value
		)
	]
	link-rule: [
		'link 
		set value [string! | char!]
		(append stack form value)
		set value url!
		(
			append stack value
			set-font fonts/link
			area-type: 'link
			; TODO:  penultimate: func [series] [skip tail series -2]
			process-text take skip tail stack -2
			set-font fonts/text
		)
	]
	newline-rule: [
		'newline
		(value: none)
		opt [set value 'blank]
		(either value [
			fix-height
			init-line/blank
		] [
			fix-height
			init-line
		])
	]
	para-rule: [
		'para any [
			'indent set value [pair! | integer!] (either pair? value [para/indent: value] [para/indent/x: value])
		|	'origin set value pair! (para/origin: value)
		|	'margin set value pair! (para/margin: value)
		|	'tabs set value [integer! | block!] (para/tabs: value)
		]
		(init-para)
	]
	bullet-rule: [
		'bullet (
			append out compose/deep [push [pen black fill-pen 0.0.0 ellipse (pos + 3x6) 6x6]]
			pos/x: pos/x + 15
		)
	]
	tab-rule: [
		'tab (
			switch type?/word para/tabs [
				block!		[
					tabs: para/tabs
					forall tabs [if pos/x < tabs/1 [pos/x: tabs/1 break]]
				]
				integer!	[
					pos/x: pos/x / para/tabs + 1 * para/tabs
				]
			]
		)
	]
	image-rule: [
		'image
		set value file!
		(
		;	set 'some-image load value
		;	append out [image some-image 0x0 20x20]
		;	process-text " :) "
		)
	]

	; --- main code

	width: either integer? with [with] [with/size/x]

	init-para
	parse dialect [
		some [
			font-rule
		|	link-rule
		|	text-rule
		|	bullet-rule
		|	newline-rule
		|	tab-rule
		|	para-rule
		]
	]
	fix-height
	case [
		object? with [
			with/draw: out
			with
		]
		info [make-info]
		true [out]
	]
]

; --- testing

rich: function [
	value
	width
	/wide
] [
	view layout compose/deep [
		image 
			253.246.227 
			(as-pair width width * either wide [0.75] [1.66]) 
			draw [(rich-text value width)]
	]
]

check-actors: does [
	rt: rich-text/info ["text " link "asdfg" https://introducing.red " text"] 300
	l: layout [t: image white 300x300 draw rt/data]
	
	t/actors: rt/actors
	t/extra: object [highlight: none]
	t/flags: [all-over]
	
	view l 
]
