package main

import (
	"errors"
	"flag"
	"fmt"
	"os"

	"github.com/go-math/format/mat"
)

var config = flag.String("config", "", "")
var input = flag.String("input", "", "")
var output = flag.String("output", "", "")

func main() {
	if len(os.Args) == 1 {
		printUsage()
		return
	}

	var command func(*problem, *mat.File, *mat.File) error
	var problem *problem
	var ifile, ofile *mat.File

	if command = findCommand(os.Args[1]); command == nil {
		printError(errors.New("the command is unknown"))
		return
	}

	// Remove the command name.
	os.Args[1] = os.Args[0]
	os.Args = os.Args[1:]

	flag.Parse()

	if len(*config) == 0 {
		printError(errors.New("a problem specification is required"))
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

	if problem, err = newProblem(config); err != nil {
		printError(err)
		return
	}

	if len(*input) > 0 {
		if ifile, err = mat.Open(*input, "r"); err != nil {
			printError(err)
			return
		}
		defer ifile.Close()
	}

	if len(*output) > 0 {
		if ofile, err = mat.Open(*output, "w7.3"); err != nil {
			printError(err)
			return
		}
		defer ofile.Close()
	}

	if err = command(problem, ifile, ofile); err != nil {
		printError(err)
		return
	}
}

func findCommand(name string) func(*problem, *mat.File, *mat.File) error {
	switch name {
	case "construct":
		return doConstruct
	case "assess":
		return doAssess
	default:
		return nil
	}
}

func printUsage() {
	fmt.Printf(
`Usage: solve <command> [options]

Commands:
    construct - to construct a surrogate model
    assess    - to construct a surrogate model

Options:
    config    - a problem specification in JSON (required)
    input     - an input MAT file
    output    - an output MAT file
`)
}

func printError(err error) {
	fmt.Printf("Error: %s.\n", err)
}
