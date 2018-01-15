package main

import (
    "fmt"
    "testing"
)

type MeowTestCase struct {
    input int
    output string
}

var gTestCases = []MeowTestCase{
    {0, ""},
    {1, "meow! "},
    {5, "meow! meow! meow! meow! meow! "},
    {10, "meow! meow! meow! meow! meow! meow! meow! meow! meow! meow! "},
}

func TestMeow(t *testing.T) {
    for _, testCase := range gTestCases {
        actualOutput := Meow(testCase.input)
        if actualOutput != testCase.output {
            fmt.Printf("Expected: %v\n", testCase.output)
            fmt.Printf("Actual: %v\n", actualOutput)
            t.FailNow()
        }
    }
}
