Red [
	Title: "Rich Text Dialect"
	Author: "Boleslav Březovský"
	File: %rich-text.red
	Rights: "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
	}
	Date: "23-10-2016"
	Note: {
		Rich Text Dialect takes Lest source and converts it to Draw dialect
		that can be supplied to Red/View.
	}
	To-Do: {
		Links should be part of Rich Text Dialect.
	}
]

; --- fonts

fonts: #()
fonts/base: make font! [
	name: "Segoe UI"
	size: 10
	color: 30.30.30
	style: []
	anti-alias?: yes
]

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

make-fonts [
	text: base 10
	bold: #bold
	italic: #italic
	underline: #underline
	link: #bold 120.60.60
	active-link: #bold 220.160.160
	fixed: "Lucida Console"
]

; -----------

whitespace?: function [
	char
] [
	find " ^/" char
]

; ----------------


rich-text: function [
	"Return Draw block created from Rich Text Dialect"
	dialect "Rich Text Dialect input"
	width "Width to wrap text at"
	/info "Return block! with output as first item and info as others (currently SIZE)"
] [
	emit-text: func [/local text area] [
		unless empty? line [
			text: copy line
			append out reduce ['text as-pair start-pos char-size/y text]
			area: make map! compose [
				type: (area-type)
				offset: (as-pair start-pos y-pos)
				size: (size-text/with face text)
				text: (text)
			]
			if equal? 'link area-type [
				area/link: take/last stack
			]
			append areas area
			blocks: blocks + 1
		]
	]

	fix-height: does [
		; --- place blocks on Y-axis
		out: tail out
		while [not zero? blocks] [
			if pair? out/1 [
				out/1/y: y-pos + line-height - out/1/y ;+ font-offset
				blocks: blocks - 1
			]
			out: back out
		]
		out: head out
		; ---
	]

	process-text: func [
		text
	] [
		start-pos: x-pos
		char-size: 0x0
;		print ["Process:" start-pos mold text]
		clear line
		clear word
		foreach char text [
			char-size: size-text/with face form char
			if char-size/y > line-height [line-height: char-size/y]
			x-pos: x-pos + char-size/x
			case [
				whitespace? char (
					append word char
					either any [
						x-pos > width
						equal? newline char
					] [
						if equal? newline char [append line head remove back tail copy word]
						emit-text
						fix-height
						clear line
						start-pos: x-pos: 0
						y-pos: y-pos + line-height
						line-height: 0
					] [
						append line copy word
					]
					clear word
				)
				equal? #"^-" char (
					append word "    " ;tab-size
				)
				true (
					append word char
				)
			]
		]
		append line word
		emit-text
		fix-height
	]

	out: make block! 2000
	font: none
	value: none
	stack: make block! 20
	line-width: 0
	start-pos: 0
	x-pos: 0
	y-pos: 0
	blocks: 0
	font-offset: 0
	line-height: 0
	line-spacing: 3 ; FIXME: Hardcoded height
	line: make string! 200
	word: make string! 50
	areas: make block! 50
	area-type: none

	face: make face! [
		font: fonts/text
	]

	set-font: func [
		font
	] [
		repend out ['font font]
		face/font: font
		font-offset: line-height - line-spacing - second size-text/with face "M"
	]

	font-rule: [
		'font set value [word! | path!] 
		(set-font get value)
	]
	text-rule: [
		set value string! 
		(
			area-type: 'area
			process-text value
		)
	]
	link-rule: [
		'link 
		set value string! 
		(append stack value)
		set value url!
		(
			append stack value
			set-font fonts/link
			area-type: 'link
			; TODO:  penultimate: func [series] [skip tail series -2]
			process-text take skip tail stack -2
		)
	]

	parse dialect [some [font-rule | link-rule | text-rule]]
	either info [reduce [out as-pair width y-pos + line-height areas]] [out]
]
