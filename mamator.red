Red [
	Title: "Mamator - Markdown editor"
]

do %fonts.red
do %import-md.red
do %lest.red
do %rich-text.red

clear fonts

fonts/base: make font! [
	name: "Arial"
	size: 14
	color: 131.148.150
	style: []
	anti-alias?: yes
]

make-fonts [
	text: :base 14 7.54.66 ;88.110.117
	bold: :text #bold
	italic: :text #italic
	underline: #underline
	link: #bold 38.139.210
	active-link: :link #underline
	fixed: "Lucida Console" 42.161.152
	nick: :underline 181.137.0
	emoji: "Segoe UI Symbol" 12 #bold 203.75.22
	h1: :text 32 #bold
	h2: :text 28 #underline
	h3: :text 24 #bold
	h4: :text 20 #bold
	h5: :text 18 #bold
	h6: :text 16 #bold 147.161.161
]

css: stylize load %styles.red

commands: context [
	new-file: does [
		clear editor/text
		clear display/draw
	]
	exit-ide: does [unview lay] ; NOTE: or quit
]

; ---

editor:		none
display:	none

lay: layout [
	styles css
	editor: area 400x500
		on-key-up [
			data: rich-text/info lest import-md editor/text 550
			display/size/y: data/size/y
			display/draw: data/data
			display/actors: data/actors
		]
	panel [display: base 600x500 253.246.227]
	scroller
]

lay/menu: [
	"&File" [
		"&New File^-Ctrl+N"					new-file
		"&Open File^-Ctrl+O" 				open-file
		"Save^-Ctrl+S"						save-file
		"Save as...^-Ctrl+Shift+S"			save-as-file
		---
		"&Close File^-Ctrl+W"				close-file 
		"&Revert File"						revert-file 
		---
		"Exit" 								exit-ide	
	]
]

lay/actors: object [
	on-menu: function [face event] [
		do get in commands event/picked
	]
]

display/extra: object [highlight: none]
display/flags: [all-over]

view lay