Red [
	Note: {
This file is intended as controller for low memory systems.
Beacuse downloading messages eats memory like mad, Red can crash.
We can solve this by having script that will call downloader in loop,
until downloader finishes succesfully. We will test for finish with a file,
that will be written only when download finishes.
}
]

dld-script: {Red[]
do %stats.red
status: load %status
get-data
status/finished?: true
save %status status
}


init-download: func [
	"Write info file"
][
	write %download.red dld-script
	save %status [
		finished?: false
	]
]

run-download: func [
	/local status step
][
	step: 1
	until [
		print ["Downloading data, step" step]
		step: step + 1
		; NOTE: This expects RED to be in your path.
		; TODO: Add some settings and maybe a test for RED present in path
		call/wait "red download.red"
		status: construct load %status
		status/finished?
	]
	print ["Data downloaded"]
]

init-download
run-download
