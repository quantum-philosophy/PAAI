package main

import (
	"errors"
	"fmt"

	"github.com/go-math/format/mat"
	"github.com/go-math/numan/interp/adhier"
	"github.com/go-math/prob/sample"
	"github.com/go-math/stat/assess"
)

func doConstruct(p *problem, _ *mat.File, f *mat.File) error {
	fmt.Println(p)

	var s *adhier.Surrogate
	track("Constructing a surrogate...", true, func() {
		s = p.solve()
	})

	fmt.Println(s)

	if f == nil {
		return nil
	}

	if err := f.Put("surrogate", *s); err != nil {
		return err
	}

	return nil
}

func doAssess(p *problem, fi *mat.File, fo *mat.File) error {
	s := new(adhier.Surrogate)
	if fi == nil {
		return errors.New("an input file is required")
	}
	if err := fi.Get("surrogate", s); err != nil {
		return err
	}

	fmt.Println(p)
	fmt.Println(s)

	c := &p.config

	if c.Samples == 0 {
		return errors.New("the number of samples is zero")
	}

	sample.Seed(c.Seed)
	points := sample.Uniform(c.Samples * p.ic)

	var values, realValues []float64

	track("Evaluating the surrogate model...", true, func() {
		values = p.evaluate(s, points)
	})

	track("Evaluating the original model...", true, func() {
		realValues = p.compute(points)
	})

	fmt.Printf("NRMSE: %e\n", assess.NRMSE(values, realValues))

	if fo == nil {
		return nil
	}

	if err := fo.PutMatrix("points", points, p.ic, c.Samples); err != nil {
		return err
	}

	if err := fo.PutMatrix("values", values, p.oc, c.Samples); err != nil {
		return err
	}

	if err := fo.PutMatrix("realValues", realValues, p.oc, c.Samples); err != nil {
		return err
	}

	return nil
}
