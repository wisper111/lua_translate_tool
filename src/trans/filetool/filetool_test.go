package filetool_test

import (
	"fmt"
	"testing"
	"trans/filetool"
)

func Test_ReadFileLine(t *testing.T) {
	ft := filetool.GetInstance()
	context, err := ft.ReadFileLine("test.txt")
	if err != nil {
		t.Fatal(err)
	}
	fmt.Println(len(context))
	for k, v := range context {
		fmt.Printf("%d %s\n", k, v)
	}
}

func Test_SaveFileLine(t *testing.T) {
	ft := filetool.GetInstance()
	context1, err := ft.ReadFileLine("test1.txt")
	if err != nil {
		t.Fatal(err)
	}
	fmt.Println(len(context1))
	for k, v := range context1 {
		fmt.Printf("%d %s\n", k, v)
	}
	err = ft.SaveFileLine("test1.txt", context1)
	if err != nil {
		fmt.Println(err)
	}
}

func Test_GetInstance(t *testing.T) {
	ft1 := filetool.GetInstance()
	ft2 := filetool.GetInstance()
	if ft1 != ft2 {
		t.Fatal("GetInstance diffrent value")
	}
}

func Test_ReadAll(t *testing.T) {
	ft := filetool.GetInstance()
	bv, err := ft.ReadAll("test.txt")
	if err != nil {
		t.Fatal(err)
	}
	fmt.Printf("%s\n", bv)
}

func Test_GetFileMap(t *testing.T) {
	ft := filetool.GetInstance()
	fm, err := ft.GetFilesMap("../", "go")
	if err != nil {
		t.Fatal(err)
	}
	for _, v := range fm {
		fmt.Println(v)
	}
}

func Test_WriteAll(t *testing.T) {
	ft := filetool.GetInstance()
	bv, err := ft.ReadAll("test.txt")
	if err != nil {
		t.Fatal(err)
	}
	err = ft.WriteAll("test/test/test.txt", bv)
	if err != nil {
		t.Fatal(err)
	}
	fmt.Printf("%s\n", bv)
	err = ft.WriteAll("test2.txt", bv)
	if err != nil {
		t.Fatal(err)
	}
}

func Benchmark_SaveFileLine(b *testing.B) {
	ft := filetool.GetInstance()
	for i := 0; i < b.N; i++ {
		context, err := ft.ReadFileLine("test.txt")
		if err != nil {
			b.Fatal(err)
		}
		ft.SaveFileLine("test.txt", context)
	}
}
