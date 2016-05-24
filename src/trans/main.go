package main

import (
	"fmt"
	"os"
	"strings"
	"trans/functool"

	//	"github.com/profile"
)

func useage() {
	fmt.Println(
		`trans is a tool for extract chinese, update dictionary and translate lua script.

Usage:	trans command [arguments]

The commands are:

	getstring	extract chinese from file or folder.
			e.g. trans getstring path				
	update		update translation to dictionary.
			e.g. trans update chinese.txt viet.txt				
	translate	translate lua script.
			e.g. trans translate src_path des_path
	
Remark: Only supports the same encoded files, such as UTF-8`)
}

func main() {
	//	defer profile.Start(profile.CPUProfile).Stop()
	//	defer profile.Start(profile.MemProfile).Stop()
	switch len(os.Args) {
	case 3:
		if strings.EqualFold(os.Args[1], "getstring") {
			functool.GetString(os.Args[2])
		} else {
			useage()
		}
	case 4:
		if strings.EqualFold(os.Args[1], "update") {
			functool.Update(os.Args[2], os.Args[3])
		} else if strings.EqualFold(os.Args[1], "translate") {
			functool.Translate(os.Args[2], os.Args[3])
		} else {
			useage()
		}
	default:
		useage()
	}
}
