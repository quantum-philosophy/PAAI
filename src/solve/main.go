package main

import (
	"flag"
	"fmt"
	"time"
)

var config = flag.String("config", "", "the configuration file in JSON")

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
}
