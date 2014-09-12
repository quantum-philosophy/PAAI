package main

import (
	"flag"
	"fmt"
	"math/rand"
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

	config, err := loadConfig(*config)
	if err != nil {
		printError(err)
		return
	}

	if err = config.validate(); err != nil {
		printError(err)
		return
	}

	problem, err := newProblem(config)
	if err != nil {
		printError(err)
		return
	}

	if config.Verbose {
		fmt.Println(problem)
		fmt.Println("Constructing a surrogate...")
	}

	start := time.Now()
	surrogate := problem.solve()
	finish := time.Now()

	if config.Verbose {
		fmt.Printf("Done in %v.\n", finish.Sub(start))
		fmt.Println(surrogate)
	}

	var nodes, values []float64

	if config.Samples > 0 {
		if config.Verbose {
			fmt.Printf("Drawing %d samples...\n", config.Samples)
		}

		rand.Seed(config.Seed)

		start = time.Now()
		values, nodes = problem.sample(surrogate, config.Samples)
		finish = time.Now()

		if config.Verbose {
			fmt.Printf("Done in %v.\n", finish.Sub(start))
		}
	}

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

	if config.Samples == 0 {
		return
	}

	err = file.PutMatrix("nodes", nodes, problem.ic, config.Samples)
	if err != nil {
		printError(err)
		return
	}

	err = file.PutMatrix("values", values, problem.oc, config.Samples)
	if err != nil {
		printError(err)
		return
	}
}
