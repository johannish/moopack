#!/usr/local/bin/tclsh

# A stupid compression algorithm (at least as dumb as a cow).

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


variable WORD_SIZE 7 

proc compress {infile} {
	variable WORD_SIZE
	set header {}
	set packed {}
	#set fsize [file size $filename]
	set channelid [open $infile r]

	while {![eof $channelid]} { ;# As the wiki warned me, there is some bug here where I read an extra newline
		set chars [read $channelid $WORD_SIZE]
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
	set separatorIndex [string last ` $data]
	if {$separatorIndex == -1} {
		puts stderr {Malformed moopack file.}
		exit 1;
	}
	set header [string range $data 0 $separatorIndex-1]
	set packed [string range $data $separatorIndex+1 end]
	set refs [split $packed .]
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

