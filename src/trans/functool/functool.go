package functool

import (
	"bytes"
	"errors"
	"fmt"
	"log"
	"strings"
	"trans/analysis"
	"trans/dic"
	"trans/filetool"
)

const (
	const_filter       string = "lua"
	const_ignore_file  string = "ignorefile.conf"
	const_chinese_file string = "chinese.txt"
	const_dic_file     string = "dictionary.db"
)

var filterMap map[string]string

func init() {
	filterMap = make(map[string]string)
	ft := filetool.GetInstance()
	bv, err := ft.ReadFileLine(const_ignore_file)
	if err != nil {
		ft.SaveFileLine(const_ignore_file, [][]byte{
			[]byte(";这里是忽略的文件，每个文件一行"),
			[]byte(";例如test.lua"),
			[]byte(";自动忽略注释和去空白"),
		})
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
	namev := strings.Split(name, "/")
	filename := namev[len(namev)-1]
	if _, ok := filterMap[filename]; ok {
		return errors.New(fmt.Sprintf("ingnore file: %s", filename))
	}
	filenamev := strings.Split(filename, ".")
	fileex := filenamev[len(filenamev)-1]
	if !strings.EqualFold(fileex, "lua") {
		return errors.New(fmt.Sprintf("non lua script: %s", filename))
	}
	return nil
}

func GetString(filedir string) error {
	ft := filetool.GetInstance()
	fmap, err := ft.GetFilesMap(filedir)
	if err != nil {
		return err
	}
	anal := analysis.New()
	for _, v := range fmap {
		if err := filterFile(v); err != nil {
			log.Println(err)
			continue
		}
		context, err := ft.ReadAll(v)
		if err != nil {
			log.Println(v, err)
			continue
		}
		if err := anal.Analysis(&context); err != nil {
			log.Println(v, err)
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
		return err
	}
	log.Printf("getstring finish! view %s.\n", const_chinese_file)
	return nil
}

func Update(cnFile, transFile string) error {
	ft := filetool.GetInstance()
	linetext1, err1 := ft.ReadFileLine(cnFile)
	if err1 != nil {
		return err1
	}
	linetext2, err2 := ft.ReadFileLine(transFile)
	if err2 != nil {
		return err2
	}
	linecount1 := len(linetext1)
	linecount2 := len(linetext2)
	if linecount1 != linecount2 {
		return errors.New(fmt.Sprintf("line number is not equal: %s:%d %s:%d", cnFile, linecount1, transFile, linecount2))
	}
	db := dic.GetInstance(const_dic_file)
	defer db.Close()
	var i int
	for i = 0; i < linecount1; i++ {
		if err := db.Insert(linetext1[i], linetext2[i]); err != nil {
			log.Printf("insert to db failed: %s:%s\n", linetext1[i], linetext2[i])
		}
	}
	log.Printf("update finished! line number: %d.\n", i)
	return nil
}

func Translate(src, des string) error {
	ft := filetool.GetInstance()
	fmap, err := ft.GetFilesMap(src)
	if err != nil {
		return err
	}
	var notrans [][]byte
	db := dic.GetInstance(const_dic_file)
	for _, fpath := range fmap {
		bv, err := ft.ReadAll(fpath)
		if err != nil {
			log.Println(err)
			continue
		}
		if err := filterFile(fpath); err == nil {
			anal := analysis.New()
			err = anal.Analysis(&bv)
			if err != nil {
				log.Println(err)
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
			log.Println(err)
		}
		fpath = strings.Replace(fpath, src, des, 1)
		ft.WriteAll(fpath, bv)
	}
	if len(notrans) > 0 {
		if err := ft.SaveFileLine(const_chinese_file, notrans); err != nil {
			return err
		}
		log.Printf("update %s, line number: %d.\n", const_chinese_file, len(notrans))
	}
	log.Println("translate finished!")
	return nil
}
