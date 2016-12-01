Red [
	Title: "Fonts Dialect"
	Author: "Boleslav Březovský"
	File: %fonts.red
	Rights: "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
	}
	Date: "1-12-2016"
	Documentation: {
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

All font properties can be `word!` also, i.e. instead of 
`red-font: :base 255.0.0` it is possible to write `red-font: :base red`.
	}
]

fonts: #()

make-fonts: function [
	spec
] [
	font: none
	styles: clear []
	mark: none
	get-word: [
		mark:
		change set value word! (probe get probe value)
		:mark
	]
	properties: [
		set name string!
	|	set size integer!
	|	set color tuple!
	|	set style issue! (append styles load form style)
	]
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
				opt get-word 
				properties
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

; --- define colors
solarized-palette: [
	base03: 0.43.54
	base02: 7.54.66
	base01: 88.110.117
	base00: 101.123.131
	base0: 131.148.150
	base1: 147.161.161
	base2: 238.232.213
	base3: 253.246.227
	yellow: 181.137.0
	orange: 203.75.22
	red: 220.50.47
	magenta: 211.54.130
	violet: 108.113.196
	blue: 38.139.210
	cyan: 42.161.152
	green: 133.153.0
]

colors: solarized-palette

; --- init FONTS

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
	text: :base 10 88.110.117
	bold: :text #bold
	italic: :text #italic
	underline: #underline
	link: #bold 38.139.210
	active-link: :link #underline
	fixed: "Lucida Console" 42.161.152
	nick: :underline 181.137.0
	emoji: "Segoe UI Symbol" 12 #bold 203.75.22
]

; dark
make-fonts [
	text: :base 10 147.161.161
	bold: :text #bold
	italic: :text #italic
	underline: #underline
	link: #bold 38.139.210
	active-link: :link #underline
	fixed: "Lucida Console" 42.161.152
	nick: :underline 181.137.0
	emoji: "Segoe UI Symbol" 12 #bold 203.75.22
]