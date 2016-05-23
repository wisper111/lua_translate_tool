package functool

import (
	"bytes"
	"errors"
	"fmt"
	"log"
	"strings"
	"time"
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
var logSlice [][]byte

func init() {
	filterMap = make(map[string]string)
	ft := filetool.GetInstance()
	bv, err := ft.ReadFileLine(const_ignore_file)
	if err != nil {
		bv = [][]byte{
			[]byte(";这里是忽略的文件，每个文件一行"),
			[]byte(";例如test.lua"),
			[]byte(";自动忽略注释和去空白"),
			[]byte("cvs"),
			[]byte(".git"),
			[]byte(".svn"),
		}
		ft.SaveFileLine(const_ignore_file, bv)
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
		return errors.New(fmt.Sprintf("non-%s", const_filter))
	}
	namev := strings.Split(name, "/")
	for _, filename := range namev {
		if _, ok := filterMap[filename]; ok {
			return errors.New(fmt.Sprintf("ingnore file"))
		}
	}
	return nil
}

func GetString(filedir string) error {
	ft := filetool.GetInstance()
	fmap, err := ft.GetFilesMap(filedir)
	if err != nil {
		addLog(fmt.Sprintf("[%s] %s", err.Error(), filedir))
		return err
	}
	anal := analysis.New()
	for i := 0; i < len(fmap); i++ {
		if err := filterFile(fmap[i]); err != nil {
			addLog(fmt.Sprintf("[%s] %s", err.Error(), fmap[i]))
			continue
		}
		context, err := ft.ReadAll(fmap[i])
		if err != nil {
			addLog(fmt.Sprintf("[%s] %s", err.Error(), fmap[i]))
			continue
		}
		if err := anal.Analysis(&context); err != nil {
			addLog(fmt.Sprintf("[%s] %s", err.Error(), fmap[i]))
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
		addLog(fmt.Sprintf("[%s] %s", err.Error(), const_chinese_file))
		return err
	}
	addLog(fmt.Sprintf("generate %s, view it.\n", const_chinese_file))
	return nil
}

func Update(cnFile, transFile string) error {
	ft := filetool.GetInstance()
	linetext1, err1 := ft.ReadFileLine(cnFile)
	if err1 != nil {
		addLog(fmt.Sprintf("[%s] %s", err1.Error(), cnFile))
		return err1
	}
	linetext2, err2 := ft.ReadFileLine(transFile)
	if err2 != nil {
		addLog(fmt.Sprintf("[%s] %s", err2.Error(), transFile))
		return err2
	}
	linecount1 := len(linetext1)
	linecount2 := len(linetext2)
	if linecount1 != linecount2 {
		err := errors.New(fmt.Sprintf("line number is not equal: %s:%d %s:%d", cnFile, linecount1, transFile, linecount2))
		addLog(err)
		return err
	}
	db := dic.GetInstance(const_dic_file)
	defer db.Close()
	var count int = 0
	for i := 0; i < linecount1; i++ {
		if err := db.Insert(linetext1[i], linetext2[i]); err != nil {
			addLog(fmt.Sprintf("insert to db failed: %s:%s\n", linetext1[i], linetext2[i]))
		} else {
			count++
		}
	}
	if count != linecount1 {
		err := errors.New(fmt.Sprintf("only insert %d line to dic, total %d.", count, linecount1))
		addLog(err)
		return err
	}
	addLog(fmt.Sprintf("update %d/%d line number to dic.\n", count, linecount1))
	return nil
}

func Translate(src, des string) error {
	ft := filetool.GetInstance()
	fmap, err := ft.GetFilesMap(src)
	if err != nil {
		addLog(fmt.Sprintf("[%s] %s", err.Error(), src))
		return err
	}
	var notrans [][]byte
	db := dic.GetInstance(const_dic_file)
	for i := 0; i < len(fmap); i++ {
		bv, err := ft.ReadAll(fmap[i])
		if err != nil {
			addLog(fmt.Sprintf("[%s] %s", err.Error(), fmap[i]))
			continue
		}
		if err := filterFile(fmap[i]); err == nil {
			anal := analysis.New()
			err = anal.Analysis(&bv)
			if err != nil {
				addLog(fmt.Sprintf("[%s] %s", err.Error(), fmap[i]))
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
			addLog(fmt.Sprintf("[%s] %s", err.Error(), fmap[i]))
		}
		fpath := strings.Replace(fmap[i], src, des, 1)
		ft.WriteAll(fpath, bv)
	}
	if len(notrans) > 0 {
		if err := ft.SaveFileLine(const_chinese_file, notrans); err != nil {
			addLog(fmt.Sprintf("[%s] %s", err.Error(), const_chinese_file))
			return err
		}
		addLog(fmt.Sprintf("update %s, not translate line number: %d.\n", const_chinese_file, len(notrans)))
	}
	return nil
}

func addLog(l interface{}) {
	switch l.(type) {
	case string:
		text := fmt.Sprintf("%s: %s", time.Now().String(), l.(string))
		logSlice = append(logSlice, []byte(text))
	case []byte:
		text := fmt.Sprintf("%s: %s", time.Now().String(), l.([]byte))
		logSlice = append(logSlice, []byte(text))
	case error:
		text := fmt.Sprintf("%s: %s", time.Now().String(), l.(error).Error())
		logSlice = append(logSlice, []byte(text))
	}
}

func WriteLog() {
	ft := filetool.GetInstance()
	if err := ft.SaveFileLine(const_log_file, logSlice); err != nil {
		log.Println(err)
	}
}
