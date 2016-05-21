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
	const_chinese_file string = "chinese.txt"
	const_dic_file     string = "dictionary.db"
)

func GetString(filedir string) error {
	ft := filetool.GetInstance()
	fmap, err := ft.GetFilesMap(filedir, const_filter)
	if err != nil {
		return err
	}
	anal := analysis.New()
	for _, v := range fmap {
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
	log.Printf("getstring finish! view %s\n", const_chinese_file)
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
		return errors.New(fmt.Sprintf("line count is not equal: %s:%d %s:%d", cnFile, linecount1, transFile, linecount2))
	}
	db := dic.GetInstance(const_dic_file)
	defer db.Close()
	var i int
	for i = 0; i < linecount1; i++ {
		if err := db.Insert(linetext1[i], linetext2[i]); err != nil {
			log.Printf("insert to db failed: %s:%s\n", linetext1[i], linetext2[i])
		}
	}
	log.Printf("update finished! line count %d.\n", i)
	return nil
}

func Translate(src, des string) error {
	ft := filetool.GetInstance()
	fmap, err := ft.GetFilesMap(src, const_filter)
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
		fpath = strings.Replace(fpath, src, des, 1)
		ft.WriteAll(fpath, bv)
	}
	if len(notrans) > 0 {
		if err := ft.SaveFileLine(const_chinese_file, notrans); err != nil {
			return err
		}
		log.Printf("update %s, line count %d\n", const_chinese_file, len(notrans))
	}
	log.Println("translate finished!")
	return nil
}
