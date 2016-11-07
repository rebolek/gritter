Red []

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
			opt [set parent word!]
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
