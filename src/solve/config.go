package main

import (
	"encoding/json"
	"errors"
	"os"

	"github.com/go-eslab/tempan/expint"
)

type TempConfig expint.Config

type Config struct {
	// The TGFF file of the system at hand.
	TGFF string
	// The IDs of the cores to analyze.
	CoreIndex []uint16
	// The IDs of the tasks to analyze.
	TaskIndex []uint16
	// The IDs of the steps to analyze.
	StepIndex []uint32
	// The divider used to populate StepIndex if empty.
	StepThinning uint16
	// The multiplier used to calculate the maximal delay of a task.
	DelayRate float64
	// The configuration of the algorithm for temperature analysis.
	TempConfig
}

func newConfig(path string) (*Config, error) {
	c := new(Config)

	if err := c.load(path); err != nil {
		return nil, err
	}

	return c, nil
}

func (c *Config) load(path string) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()

	dec := json.NewDecoder(file)
	if err = dec.Decode(c); err != nil {
		return err
	}

	return nil
}

func (c *Config) validate() error {
	if c.StepThinning <= 0 {
		return errors.New("the step thining is invalid")
	}

	if c.DelayRate <= 0 {
		return errors.New("the delay rate is invalid")
	}

	if c.TimeStep <= 0 {
		return errors.New("the time step is invalid")
	}

	return nil
}
