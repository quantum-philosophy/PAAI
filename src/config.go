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
	// The strength of correlations between data-dependent tasks.
	CorrLength float64 // > 0
	// The portion of the variance to be preserved when reducing the number of
	// stochastic dimensions.
	VarPreserved float64 // ∈ (0, 1]
	// The multiplier used to calculate the maximal delay of a task.
	DelayRate float64 // >= 0

	// The IDs of the cores to analyze; if empty, set to all cores.
	CoreIndex []uint16
	// The IDs of the tasks to analyze; if empty, set to all tasks.
	TaskIndex []uint16

	// The configuration of the algorithm for temperature analysis.
	Analysis expint.Config
	// The configuration of the algorithm for interpolation.
	Interpolation adhier.Config

	// The seed for random number generation.
	Seed int64
	// The number of samples to take.
	Samples uint32

	// True to display progress information.
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
	if c.CorrLength < 0 {
		return errors.New("the correlation length is invalid")
	}
	if c.VarPreserved <= 0 || c.VarPreserved > 1 {
		return errors.New("the variance-reduction threshold is invalid")
	}
	if c.DelayRate < 0 {
		return errors.New("the delay rate is invalid")
	}
	if c.Analysis.TimeStep <= 0 {
		return errors.New("the time step is invalid")
	}

	return nil
}
