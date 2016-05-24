package dic_test

import (
	"fmt"
	"testing"
	"trans/dic"
)

func Test_Insert(t *testing.T) {
	db := dic.New("dictionary.db")
	defer db.Close()
	if err := db.Insert([]byte("测试"), []byte("ceshi")); err != nil {
		t.Error(err)
	}
}

func Test_Query(t *testing.T) {
	db := dic.New("dictionary.db")
	defer db.Close()
	ret, err := db.Query([]byte("测试"))
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println(string(ret))
	ret, err = db.Query([]byte("测试1"))
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println(string(ret))
}

func Benchmark_Insert(b *testing.B) {
	db := dic.New("dictionary.db")
	defer db.Close()
	var cn, trans string
	for i := 0; i < b.N; i++ {
		cn = fmt.Sprintf("%s%d", "测试", i)
		trans = fmt.Sprintf("%s%d", "ceshi", i)
		if err := db.Insert([]byte(cn), []byte(trans)); err != nil {
			b.Error(err)
		}
	}
}

func Benchmark_Query(b *testing.B) {
	db := dic.New("dictionary.db")
	defer db.Close()
	var cn string
	for i := 0; i < b.N; i++ {
		cn = fmt.Sprintf("%s%d", "测试", i)
		db.Query([]byte(cn))
	}
}

func Benchmark_New(b *testing.B) {
	for i := 0; i < b.N; i++ {
		db := dic.New("dictionary.db")
		db.Close()
	}
}
