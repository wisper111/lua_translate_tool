package filetool

import (
	"bufio"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

type filetool struct{}

var instance *filetool
var once sync.Once

func GetInstance() *filetool {
	once.Do(func() {
		instance = &filetool{}
	})
	return instance
}

func (ft *filetool) ReadFileLine(name string) ([][]byte, error) {
	var context [][]byte
	f, err := os.Open(name)
	defer f.Close()
	if err != nil {
		return context, err
	}
	readline := func(r *bufio.Reader) ([]byte, error) {
		var (
			isPrefix        bool  = true
			err             error = nil
			line, realyline []byte
		)
		for isPrefix && err == nil {
			line, isPrefix, err = r.ReadLine()
			realyline = append(realyline, line...)
		}
		return realyline, err
	}
	r := bufio.NewReader(f)
	err = nil
	var line []byte
	for err == nil {
		line, err = readline(r)
		if len(line) > 0 {
			context = append(context, line)
		}
	}
	return context, nil
}

func (ft *filetool) SaveFileLine(name string, context [][]byte) error {
	length := len(context)
	if length < 1 {
		return errors.New("context is empty!")
	}
	f, err := os.Create(name)
	defer f.Close()
	if err != nil {
		return err
	}
	w := bufio.NewWriter(f)
	if length > 2 {
		for _, v := range context[:length-1] {
			fmt.Fprintln(w, string(v))
		}
	}
	fmt.Fprint(w, string(context[length-1]))
	return w.Flush()
}

func (ft *filetool) GetFilesMap(path, filter string) (map[string]string, error) {
	filemap := make(map[string]string)
	f := func(path string, info os.FileInfo, err error) error {
		if !info.IsDir() {
			path = strings.Replace(path, "\\", "/", -1)
			pathv := strings.Split(path, "/")
			exn := strings.Split(pathv[len(pathv)-1], ".")
			if strings.EqualFold(filter, exn[len(exn)-1]) {
				filemap[path] = path
			}
			return err
		} else {
			return nil
		}
	}
	fpErr := filepath.Walk(path, f)
	if fpErr != nil {
		return nil, errors.New("Walk path Failed!")
	}
	return filemap, nil
}

func (ft *filetool) ReadAll(name string) ([]byte, error) {
	return ioutil.ReadFile(name)
}

func (ft *filetool) WriteAll(name string, text []byte) error {
	if index := strings.LastIndex(name, "/"); index != -1 {
		err := os.MkdirAll(name[:index], os.ModePerm)
		if err != nil {
			return err
		}
	}
	return ioutil.WriteFile(name, text, os.ModePerm)
}
