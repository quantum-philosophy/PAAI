package main

import (
	"encoding/json"
	"errors"
	"os"

	"github.com/go-eslab/tempan/expint"
	"github.com/go-math/numan/interp/adhier"
)

type Config struct {
	// The TGFF file of the system to analyze.
	TGFF string
	// The multiplier used to calculate the maximal delay of a task.
	DelayRate float64 // in [0, 1)

	// The IDs of the cores to analyze.
	CoreIndex []uint16
	// The IDs of the tasks to analyze.
	TaskIndex []uint16
	// The IDs of the steps to analyze.
	StepIndex []uint32

	// The divider used to populate StepIndex if empty.
	StepThinning uint16

	// The configuration of the algorithm for temperature analysis.
	Analysis expint.Config

	// The configuration of the algorithm for interpolation.
	Interpolation adhier.Config

	// A flag to display progress information.
	Verbose bool
}

func loadConfig(path string) (Config, error) {
	c := Config{}

	file, err := os.Open(path)
	if err != nil {
		return c, err
	}
	defer file.Close()

	dec := json.NewDecoder(file)
	if err = dec.Decode(&c); err != nil {
		return c, err
	}

	return c, nil
}

func (c *Config) validate() error {
	if c.StepThinning <= 0 {
		return errors.New("the step thining is invalid")
	}

	if c.DelayRate <= 0 {
		return errors.New("the delay rate is invalid")
	}

	if c.Analysis.TimeStep <= 0 {
		return errors.New("the time step is invalid")
	}

	return nil
}
