package main

import (
	"flag"
	"fmt"
	"math"
	"math/rand"
	"time"

	"github.com/go-math/format/mat"
	"github.com/go-math/numan/interp/adhier"
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

	fmt.Println(problem)

	var surrogate *adhier.Surrogate
	var nodes, values, realValues []float64

	track("Constructing a surrogate...", true, func() {
		surrogate = problem.solve()
	})

	fmt.Println(surrogate)

	if config.Samples > 0 {
		rand.Seed(config.Seed)
		track(fmt.Sprintf("Drawing %d samples...", config.Samples), true, func() {
			values, nodes = problem.sample(surrogate, config.Samples)
		})
	}

	if config.Samples > 0 && config.Assess {
		track("Assessing the surrogate...", true, func() {
			realValues = problem.compute(nodes)
		})

		fmt.Printf("L2 error: %e\n", computeL2(realValues, values))
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

	if !config.Assess {
		return
	}

	err = file.PutMatrix("realValues", realValues, problem.oc, config.Samples)
	if err != nil {
		printError(err)
		return
	}
}

func track(description string, verbose bool, work func()) {
	if verbose {
		fmt.Println(description)
	}

	start := time.Now()
	work()
	duration := time.Now().Sub(start)

	if verbose {
		fmt.Printf("Done in %v.\n", duration)
	}
}

func computeL2(observed, predicted []float64) float64 {
	var sum, delta float64

	for i := range observed {
		delta = observed[i] - predicted[i]
		sum += delta * delta
	}

	return math.Sqrt(sum)
}
