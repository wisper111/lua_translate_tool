package analysis_test

import (
	"fmt"
	"testing"
	"trans/analysis"
	"trans/filetool"
)

func Test_example(t *testing.T) {
	text, err := filetool.GetInstance().ReadAll("test.lua")
	if err != nil {
		t.Fatal(err)
	}
	ana := analysis.New()
	err = ana.Analysis(&text)
	if err != nil {
		t.Fatal(err)
	}
	for k, v := range ana.ChEntry {
		fmt.Printf("%d %s\n", k, v)
	}
}

func Benchmark_example(b *testing.B) {
	text, err := filetool.GetInstance().ReadAll("test.lua")
	if err != nil {
		b.Fatal("can not read file")
	}
	ana := analysis.New()
	for i := 0; i < b.N; i++ {
		err = ana.Analysis(&text)
		if err != nil {
			b.Fatal(err)
		}
	}
}
