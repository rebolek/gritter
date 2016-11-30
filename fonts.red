Red [
	Title: "Fonts Dialect"
	Author: "Boleslav Březovský"
	File: %fonts.red
	Rights: "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
	}
	Date: "30-11-2016"
	Purpose: {
# About

Fonts Dialect provides simple way to define fonts for use in Red/View.

# Usage

```
font-name: <parent-font> <name> <size> <color> <styles>
```

where

* font-name - `[set-word!]` name of font to define
* parent-font - `[get-word!]` name of parent font to inherit properties form
* name - `[string!]` name of system font to use
* size - `[integer!]` font size
* color - `[tuple!]` font color
* styles - `[issue!]` font style(s): bold, italic, underline
	}
]

fonts: #()

make-fonts: function [
	spec
] [
	font: none
	styles: clear []
	parse spec [
		some [
			(parent: 'base)
			(clear styles)
			set font set-word! 
			opt [set parent get-word!]
			(
				parent-font: fonts/:parent
				name: parent-font/name
				size: parent-font/size
				color: parent-font/color
				styles: copy parent-font/style
			)
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


; FIXME: when using FONT-NAME in definition, new font is not based on it!!!
; TODO: word! and path! support for colors (font parent as lit- or get-word)

clear fonts

fonts/base: make font! [
	name: "Segoe UI"
	size: 10
	color: 101.123.131 ; light: 131.148.150
	style: []
	anti-alias?: yes
]

; light
make-fonts [
	text: base 10 88.110.117
	bold: text #bold
	italic: text #italic
	underline: #underline
	link: #bold 38.139.210
	active-link: link #underline
	fixed: "Lucida Console" 42.161.152
	nick: underline 181.137.0
	emoji: "Segoe UI Symbol" 12 #bold 203.75.22
]

; dark
make-fonts [
	text: base 10 147.161.161
	bold: text #bold
	italic: text #italic
	underline: #underline
	link: #bold 38.139.210
	active-link: link #underline
	fixed: "Lucida Console" 42.161.152
	nick: underline 181.137.0
	emoji: "Segoe UI Symbol" 12 #bold 203.75.22
]