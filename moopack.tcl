#!/usr/local/bin/tclsh

# A stupid compression algorithm (at least as dumb as a cow).
# Currently cannot compress data which contains the backtick (`) character.

set usageStr "moopack usage: moopack.tcl c|d input_file \[output_file\]"

if {$argc < 2 || $argc > 3} {
   puts stderr $usageStr
   exit 1
}

set direction [lindex $argv 0]
if {!($direction == "d" || $direction == "c")} {
   puts stderr $usageStr
   exit 1
}
set infile [lindex $argv 1]
set outfile [lindex $argv 2]


proc compress {infile} {
	set header {}
	set packed {}
	#set fsize [file size $filename]
	set channelid [open $infile r]

	while {![eof $channelid]} { ;# As the wiki warned me, there is some bug here where I read an extra newline
		set chars [read $channelid 32]
		set index [lsearch $header $chars]
		set alreadySeen [expr $index != -1]
		if {$alreadySeen} {
			set packed $packed.$index
		} else {
			lappend header $chars
			set packed $packed.[expr [llength $header] - 1]
		}
		if [eof $channelid] break
	}

	close $channelid
	return "$header`$packed"
}

proc decompress {infile} {
	set channelid [open $infile r]
	set data [read $channelid]
	set parts [split $data "`"]
	set header1 [lrange $parts 0 end-1] ;# why does this return a nested list?
	set header [lindex $header1 0] ;# hack to unwrap list from previous line
	set packed [lindex $parts end] ;# Why does this have a trailing newline?
	set packedWithoutTrailingNewline [lrange $packed 0 0] ;# A hack I discovered to discard the trailing newline
	set refs [split $packedWithoutTrailingNewline "."]
	set refs [lrange $refs 1 end]

	set inflated {}
	foreach {i} $refs {
		set actualValue [lindex $header $i] 
		set inflated $inflated$actualValue
	}
	return $inflated
}

proc output {contents outputfile} {
	if {$outputfile != ""} {
		puts -nonewline [open $outputfile w] $contents
	} else {
		puts -nonewline stdout $contents
	}
}


switch $direction {
	c {
		puts stderr "  Packing $infile"
		output [compress $infile] $outfile
	}
	d {
		output [decompress $infile] $outfile
	}
}

