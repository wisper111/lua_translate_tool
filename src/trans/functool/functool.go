package functool

import (
	"bytes"
	"errors"
	"fmt"
	"log"
	"os"
	"strings"
	"trans/analysis"
	"trans/dic"
	"trans/filetool"
)

const (
	const_filter       string = "lua"
	const_ignore_file  string = "ignore.conf"
	const_chinese_file string = "chinese.txt"
	const_dic_file     string = "dictionary.db"
	const_log_file     string = "log.txt"
)

var filterMap map[string]string
var logFile *log.Logger
var logPrint *log.Logger

const (
	log_file = 1 << iota
	log_print
)

func writeLog(flag int, v ...interface{}) {
	if flag&log_file != 0 {
		logFile.Println(v...)
	}
	if flag&log_print != 0 {
		logPrint.Println(v...)
	}
}

func init() {
	// create logger
	flog, err := os.Create(const_log_file)
	if err != nil {
		log.Fatalln(err)
	}
	logFile = log.New(flog, "[trans]", log.LstdFlags)
	logPrint = log.New(os.Stdout, "[trans]", log.LstdFlags)
	// init or read ignore config
	filterMap = make(map[string]string)
	ft := filetool.GetInstance()
	bv, err := ft.ReadFileLine(const_ignore_file)
	if err != nil {
		writeLog(log_file, err)
		bv = [][]byte{
			[]byte(";这里是忽略的文件，每个文件一行"),
			[]byte(";例如test.lua"),
			[]byte(";自动忽略注释和去空白"),
			[]byte("cvs"),
			[]byte(".git"),
			[]byte(".svn"),
		}
		err = ft.SaveFileLine(const_ignore_file, bv)
		if err != nil {
			writeLog(log_file|log_print, err)
		}
	}
	for _, v := range bv {
		if v[0] == 0x3b {
			continue
		}
		v = bytes.Trim(v, " ")
		sv := string(v)
		filterMap[sv] = sv
	}
}

func filterFile(name string) error {
	filenamev := strings.Split(name, ".")
	fileex := filenamev[len(filenamev)-1]
	if !strings.EqualFold(fileex, const_filter) {
		return errors.New(fmt.Sprintf("[non-%s] %s", const_filter, name))
	}
	namev := strings.Split(name, "/")
	for _, filename := range namev {
		if _, ok := filterMap[filename]; ok {
			return errors.New(fmt.Sprintf("[ingnore file] %s", name))
		}
	}
	return nil
}

func GetString(filedir string) {
	ft := filetool.GetInstance()
	fmap, err := ft.GetFilesMap(filedir)
	if err != nil {
		writeLog(log_file|log_print, err)
		return
	}
	anal := analysis.New()
	for i := 0; i < len(fmap); i++ {
		if err := filterFile(fmap[i]); err != nil {
			writeLog(log_file, err)
			continue
		}
		context, err := ft.ReadAll(fmap[i])
		if err != nil {
			writeLog(log_file|log_print, err)
			continue
		}
		if err := anal.Analysis(&context); err != nil {
			writeLog(log_file|log_print, err)
		}
	}
	db := dic.GetInstance(const_dic_file)
	defer db.Close()
	var ret [][]byte
	for i := 0; i < len(anal.ChEntry); i++ {
		if _, err := db.Query(anal.ChEntry[i]); err != nil {
			ret = append(ret, anal.ChEntry[i])
		}
	}
	err = ft.SaveFileLine(const_chinese_file, ret)
	if err != nil {
		writeLog(log_file|log_print, err)
		return
	}
	writeLog(log_file|log_print,
		fmt.Sprintf("generate %s, view it. getstring finished!", const_chinese_file))
	return
}

func Update(cnFile, transFile string) {
	ft := filetool.GetInstance()
	linetext1, err1 := ft.ReadFileLine(cnFile)
	if err1 != nil {
		writeLog(log_file|log_print, err1)
		return
	}
	linetext2, err2 := ft.ReadFileLine(transFile)
	if err2 != nil {
		writeLog(log_file|log_print, err2)
		return
	}
	linecount1 := len(linetext1)
	linecount2 := len(linetext2)
	if linecount1 != linecount2 {
		writeLog(log_file|log_print, fmt.Sprintf("line number is not equal: %s:%d %s:%d",
			cnFile, linecount1, transFile, linecount2))
		return
	}
	db := dic.GetInstance(const_dic_file)
	defer db.Close()
	var count int = 0
	for i := 0; i < linecount1; i++ {
		if err := db.Insert(linetext1[i], linetext2[i]); err != nil {
			writeLog(log_file|log_print,
				fmt.Sprintf("insert to db failed: %s:%s", linetext1[i], linetext2[i]))
		} else {
			count++
		}
	}
	if count != linecount1 {
		writeLog(log_file|log_print,
			fmt.Sprintf("only insert %d line to dic, total %d.", count, linecount1))
		return
	}
	writeLog(log_file|log_print,
		fmt.Sprintf("update %d/%d line number to dic. update finished!", count, linecount1))
	return
}

func Translate(src, des string) {
	ft := filetool.GetInstance()
	fmap, err := ft.GetFilesMap(src)
	if err != nil {
		writeLog(log_file|log_print, err)
		return
	}
	var notrans [][]byte
	db := dic.GetInstance(const_dic_file)
	for i := 0; i < len(fmap); i++ {
		bv, err := ft.ReadAll(fmap[i])
		if err != nil {
			writeLog(log_file|log_print, err)
			continue
		}
		if err := filterFile(fmap[i]); err == nil {
			anal := analysis.New()
			err = anal.Analysis(&bv)
			if err != nil {
				writeLog(log_file|log_print, err)
				continue
			}
			for _, t := range anal.ChEntry {
				trans, err := db.Query(t)
				if err != nil {
					notrans = append(notrans, t)
					continue
				}
				bv = bytes.Replace(bv, t, trans, -1)
			}
		} else {
			writeLog(log_file, err)
		}
		fpath := strings.Replace(fmap[i], src, des, 1)
		ft.WriteAll(fpath, bv)
	}
	if len(notrans) > 0 {
		if err := ft.SaveFileLine(const_chinese_file, notrans); err != nil {
			writeLog(log_file|log_print, err)
			return
		}
		writeLog(log_file|log_print,
			fmt.Sprintf("update %s, not translate line number: %d.", const_chinese_file, len(notrans)))
	}
	writeLog(log_file|log_print, "translate finished!")
	return
}
