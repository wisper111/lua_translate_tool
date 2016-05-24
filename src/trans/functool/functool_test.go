package functool_test

import (
	"fmt"
	"testing"
	"trans/dic"
	"trans/functool"
)

func Test_GetString(t *testing.T) {
	functool.GetString("test")
	functool.GetString("f:/bqp/bqp/client1")
}

func Test_Update(t *testing.T) {
	functool.Update("test/cn.txt", "test/en.txt")
	db := dic.New("dictionary.db")
	defer db.Close()
	ret, err := db.Query([]byte("你好，世界！"))
	if err != nil {
		t.Fatal(err)
	}
	fmt.Printf("%s\n", ret)
	functool.Update("test/cn.txt", "test/test.lua")
}

func Test_Translate(t *testing.T) {
	functool.Translate("test/cn", "test/en")
}

func Benchmark_GetString(b *testing.B) {
	for i := 0; i < b.N; i++ {
		functool.GetString("test")
	}
}

func Benchmark_Update(b *testing.B) {
	for i := 0; i < b.N; i++ {
		functool.Update("test/cn.txt", "test/en.txt")
	}
}

func Benchmark_Translate(b *testing.B) {
	for i := 0; i < b.N; i++ {
		functool.Translate("test/cn", "test/en")
	}
}
