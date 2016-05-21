package main

import (
	"fmt"
	"log"
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

	getstring    extract chinese from file or folder.
				 e.g. trans getstring path
				
	update       update translation to dictionary.
				 e.g. trans update chinese.txt viet.txt
				
	translate    translate lua script.
				 e.g. trans translate src_path des_path
	
Remark: Only support UFT-8 encoding`)
}

func main() {
	//	defer profile.Start(profile.CPUProfile).Stop()
	//	defer profile.Start(profile.MemProfile).Stop()
	switch len(os.Args) {
	case 3:
		if strings.EqualFold(os.Args[1], "getstring") {
			if err := functool.GetString(os.Args[2]); err != nil {
				log.Println(err)
			}
		} else {
			useage()
		}
	case 4:
		if strings.EqualFold(os.Args[1], "update") {
			if err := functool.Update(os.Args[2], os.Args[3]); err != nil {
				log.Println(err)
			}
		} else if strings.EqualFold(os.Args[1], "translate") {
			if err := functool.Translate(os.Args[2], os.Args[3]); err != nil {
				log.Println(err)
			}
		} else {
			useage()
		}
	default:
		useage()
	}
}
