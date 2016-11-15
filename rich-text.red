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
					append word char
					size-word
					; check if we need to wrap
					if any [
						pos/x > width 			; we are after the line, wrap
						equal? newline char 	; newline wraps automatically
					] [
						; do wrapping - emit line and move to next line
						emit-text
						fix-height
						init-line
						size-word
					]
					; append word to line
					append line copy word
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

	init-para: func [] [
		pos/x: para/indent
		pos/y: pos/y + line-height
		line-height: 0
	]

	init-line: func [] [
		start-pos: 0
		pos/x: 0
		pos/y: probe pos/y + line-height
		line-height: 0
		clear line
	]

	size-word: func [] [
		; get position after the word
		word-size: size-text/with face word
		pos/x: pos/x + word-size/x
		if word-size/y > line-height [line-height: word-size/y]
	]

	; --- parse rules

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

	image-rule: [
		'image
		set value file!
		(
		;	set 'some-image load value
		;	append out [image some-image 0x0 20x20]
		;	process-text " :) "
		)
	]

	parse dialect [some [font-rule | link-rule | text-rule]]
	fix-height
	either info [reduce [out as-pair width pos/y + line-height areas]] [out]
]
