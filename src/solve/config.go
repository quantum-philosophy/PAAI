package main

import (
	"encoding/json"
	"errors"
	"os"

	"github.com/go-eslab/tempan/expint"
)

type ExpInt expint.Config

type Config struct {
	TGFF string

	coreIndex []uint16
	taskIndex []uint16

	ExpInt
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
	if c.TimeStep <= 0 {
		return errors.New("the time step is invalid")
	}

	return nil
}
