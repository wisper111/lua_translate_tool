package dic_test

import (
	"fmt"
	"testing"
	"trans/dic"
)

func Test_InsertString(t *testing.T) {
	db := dic.New("dictionary_viet.db")
	defer db.Close()
	if err := db.InsertString("测试", "ceshi"); err != nil {
		t.Error(err)
	}
}

func Test_QueryString(t *testing.T) {
	db := dic.New("dictionary_viet.db")
	defer db.Close()
	ret, err := db.QueryString("测试")
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println(ret)
	ret, err = db.QueryString("测试1")
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println(ret)
}

func Benchmark_InsertString(b *testing.B) {
	db := dic.New("dictionary_viet.db")
	defer db.Close()
	var cn, trans string
	for i := 0; i < b.N; i++ {
		cn = fmt.Sprintf("%s%d", "测试", i)
		trans = fmt.Sprintf("%s%d", "ceshi", i)
		if err := db.InsertString(cn, trans); err != nil {
			b.Error(err)
		}
	}
}

func Benchmark_QueryString(b *testing.B) {
	db := dic.New("dictionary_viet.db")
	defer db.Close()
	var cn string
	for i := 0; i < b.N; i++ {
		cn = fmt.Sprintf("%s%d", "测试", i)
		db.QueryString(cn)
	}
}
