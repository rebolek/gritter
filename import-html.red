Red [
	Title: "HTML to Lest convertor"
	File: %import-html.red
	Author: "Boleslav Březovský"
	Date: "22-11-2016"
	Rights: "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
	}
]

import-html: function [
	dialect [string!]
] [
	out: make block! 50

	tag: none
	text: make string! 200
	data: none
	mark: none
	value: none
	stack: make block! 20
	tags: make block! 20

	open-tag: #"<"
	open-end-tag: "</"
	close-tag: #">"
	heading-size: charset [#"1" - #"6"]
	whitespace: charset [#" " #"^/" #"^-"]

	; --- funcs

	emit: func [
		value
	] [
		; --- emit text buffer
		text: trim text
		unless empty? text [
			mark: insert mark copy text			
		]

		; --- emit tag
		either value [
			; emit value - tag is opening
			insert mark value: reduce value
			either block? last value [
				append/only stack mark: last value
			] [mark: tail mark]
		] [
			; emit none - tag is closing, pop stack
			take/last stack
			mark: tail last stack
		]

		; --- clean up and return position
		clear text
		value: none
		mark
	]

	; --- rules

	debug: [
		p: (print ["now at" mold p])
	]

	body: [
		heading-rule
	|	tag-rule
	|	link-rule
	|	text-rule	
	]

	body-rule: [
		thru {<body}
		thru close-tag
		some body
		(emit none)
		</body>
		to end
	]
	
	text-rule: [
		not open-tag
		set value skip
		(append text value)
	]

	tag-rule: [
		open-tag
		; TODO: PRE should prevent newline and whitespaces - perhaps separate rule
		copy tag ["span" | "div" | "pre" | "p" | "b" | "i"] 
		p: (
			if all [equal? "p" tag equal? "p" last tags] [
				tag: take/last tags
				emit none
			]
		)
		(append tags tag)
		[close-tag | whitespace thru close-tag]
		(mark: emit [to word! tag make block! 20])
		some body
		(tag: take/last tags)
		open-end-tag 
		tag
		close-tag
		(emit none)
	]

	link-rule: [
		open-tag
		copy tag "a"
		any whitespace
		{href=}
		opt #"^""
		copy data
		[to #"^"" | to close-tag | to whitespace]
		thru close-tag
		copy value
		to open-end-tag
		open-end-tag
		tag
		close-tag
		(mark: emit ['link either equal? #"/" first data [to file! data] [to url! data] value])
	]

	heading-rule: [
		open-tag
		copy tag [#"h" heading-size]
		thru close-tag
		copy value
		to open-end-tag
		2 skip
		tag
		close-tag
		(emit [to word! tag value])
	]

	list-item: [
		open-tag
		"li"
		thru close-tag
	]

	list-rule: [
		open-tag
		"ul" ; TODO: ordered list
		thru close-tag
		some [
			open-tag
			"li"
		]
	]

	rules: [
	;	body-rule
		some body
	]

	; --- main

	mark: tail out
	append/only stack mark
	parse dialect rules
;	emit none
	out
]