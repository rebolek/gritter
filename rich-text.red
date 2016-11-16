Red [
	Title: "Rich Text Dialect"
	Author: "Boleslav Březovský"
	File: %rich-text.red
	Rights: "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
	}
	Date: "7-11-2016"
	Note: {
		Rich Text Dialect takes Lest source and converts it to Draw dialect
		that can be supplied to Red/View.
	}
	To-Do: {}
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
	/info "Return block! with output as first item and info as others (currently SIZE and AREAS)"
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
		; print ["fix-height to" line-height]
		out: tail out
		while [not zero? blocks] [
			if pair? out/1 [
				out/1/y: pos/y + line-height - heights/:blocks ;+ font-offset
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
						fix-height
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

	out: make block! 2000
	font: none
	value: none
	stack: make block! 20
	line-width: 0
	start-pos: 0
	pos: 0x0
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

	para: context [
		indent: 5x0 ; Y-pos is not used right now
		origin: 5x5
		margin: 5x5
	]

	heights: make block! 20

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

	init-para: func [/first] [
		pos/x: para/indent/x + para/origin/x
		pos/y: para/origin/y + pos/y + line-height + either first [0] [para/indent/y]
		line-height: 0
	]

	init-line: func [] [
		pos/x: para/origin/x
		start-pos: pos/x
		pos/y: pos/y + line-height
		line-height: 0
		clear line
	]

	size-word: func [] [
		; FIXME: There is bug in Red, it sometimes ignores the font
		;		once the name is set again, it works as expected
		face/font/name: copy face/font/name
		word-size: size-text/with face word
		; print ["size of" mold word word-size]
		; get position after the word
		pos/x: pos/x + word-size/x
		if word-size/y > line-height [line-height: word-size/y]
	]

	do-wrap: [
		; do wrapping - emit line and move to next line
		emit-text
		fix-height
		init-line
		size-word
	]

	; --- parse rules

	font-rule: [
		'font set value [word! | path!] 
		(set-font get value)
	]
	text-rule: [
		set value [string! | char!]
		(
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
		)
	]
	newline-rule: [
		'newline
		(init-line)
	]
	para-rule: [
		'para any [
			'indent set value pair! (para/indent: value)
		|	'origin set value pair! (para/origin: value)
		|	'margin set value pair! (para/margin: value)
		]
		(init-para)
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

	init-para
	parse dialect [some [font-rule | link-rule | text-rule | newline-rule | para-rule]]
	fix-height
	either info [reduce [out as-pair width pos/y + line-height areas]] [out]
]

; --- testing

rich: function [
	value
	width
] [
	view layout compose/deep [image 253.246.227 (as-pair width width * 0.75) draw [(rich-text value width)]]
]
