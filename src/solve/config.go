package main

import (
	"encoding/json"
	"os"

	"github.com/go-eslab/tempan/expint"
)

type ExpInt expint.Config

type Config struct {
	TGFF string
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

	if err = (*expint.Config)(&c.ExpInt).Validate(); err != nil {
		return err
	}

	return nil
}
