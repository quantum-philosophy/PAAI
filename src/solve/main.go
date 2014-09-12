package main

import (
	"flag"
	"fmt"
	"time"

	"github.com/go-math/format/mat"
)

var config = flag.String("config", "", "a configuratin file in JSON")
var output = flag.String("output", "", "an output file in MAT")

func printUsage() {
	fmt.Printf("Usage: solve [options]\nOptions:\n")
	flag.PrintDefaults()
}

func printError(err error) {
	fmt.Printf("Error: %s", err)
}

func main() {
	flag.Parse()

	if len(*config) == 0 {
		printUsage()
		return
	}

	problem, err := newProblem(*config)
	if err != nil {
		printError(err)
		return
	}

	fmt.Println(problem)

	start := time.Now()
	surrogate := problem.solve()
	finish := time.Now()

	fmt.Println(surrogate)
	fmt.Println("Time elapsed:", finish.Sub(start))

	if len(*output) == 0 {
		return
	}

	file, err := mat.Open(*output, "w7.3")
	if err != nil {
		printError(err)
		return
	}
	defer file.Close()

	err = file.Put("surrogate", *surrogate)
	if err != nil {
		printError(err)
		return
	}
}
