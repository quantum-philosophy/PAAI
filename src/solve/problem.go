package main

import (
	"errors"
	"math"

	"github.com/go-eslab/persim/power"
	"github.com/go-eslab/persim/system"
	"github.com/go-eslab/persim/time"
	"github.com/go-eslab/tempan/expint"

	"github.com/go-math/numan/basis/linhat"
	"github.com/go-math/numan/grid/newcot"
	"github.com/go-math/numan/interp/adhier"
)

type problem struct {
	config *Config

	cores uint16
	tasks uint16
	steps uint16

	inputs  uint16
	outputs uint16

	priority []float64
	time     *time.List
	power    *power.Self

	tempan *expint.Self
	interp *adhier.Self
}

func newProblem(path string) (*problem, error) {
	p := &problem{}
	var err error

	p.config, err = newConfig(path)
	if err != nil {
		return nil, err
	}

	if err = p.config.validate(); err != nil {
		return nil, err
	}

	plat, app, err := system.LoadTGFF(p.config.TGFF)
	if err != nil {
		return nil, err
	}

	p.priority = system.NewProfile(plat, app).Mobility
	p.time = time.NewList(plat, app)
	p.power = power.New(plat, app, p.config.TimeStep)

	sched := p.time.Compute(p.priority)

	p.cores = uint16(len(plat.Cores))
	p.tasks = uint16(len(app.Tasks))
	p.steps = uint16(math.Floor(sched.Span() / p.config.TimeStep))

	p.inputs = uint16(len(p.config.taskIndex))
	p.outputs = uint16(len(p.config.coreIndex)) * p.steps

	p.tempan, err = expint.New((*expint.Config)(&p.config.ExpInt))
	if err != nil {
		return nil, err
	}

	p.interp = adhier.New(newcot.New(p.inputs), linhat.New(p.inputs), p.outputs)

	if err = p.validate(); err != nil {
		return nil, err
	}

	return p, nil
}

func (p *problem) solve() *adhier.Surrogate {
	return p.interp.Compute(p.evaluate)
}

func (p *problem) evaluate(nodes []float64) []float64 {
	sched := p.time.Compute(p.priority)

	P := p.power.Compute(sched)

	steps := uint16(len(P)) / p.cores

	Q := make([]float64, p.cores*steps)

	p.tempan.ComputeTransient(P, Q, uint32(p.cores), uint32(steps))

	return Q
}

func (p *problem) validate() error {
	if len(p.config.coreIndex) == 0 {
		return errors.New("the core index is empty")
	}

	for _, id := range p.config.coreIndex {
		if id >= p.cores {
			return errors.New("the core index is invalid")
		}
	}

	if len(p.config.taskIndex) == 0 {
		return errors.New("the task index is empty")
	}

	for _, id := range p.config.taskIndex {
		if id >= p.tasks {
			return errors.New("the task index is invalid")
		}
	}

	return nil
}
