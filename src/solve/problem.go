package main

import (
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

	plat, app, err := system.LoadTGFF(p.config.TGFF)
	if err != nil {
		return nil, err
	}

	p.priority = system.NewProfile(plat, app).Mobility
	p.time = time.NewList(plat, app)
	p.power = power.New(plat, app, p.config.TimeStep)

	sched := p.time.Compute(p.priority)
	steps := uint16(math.Floor(sched.Span() / p.config.TimeStep))

	p.cores = uint16(len(plat.Cores))
	p.tasks = uint16(len(app.Tasks))

	p.inputs = p.tasks
	p.outputs = p.cores * steps

	p.tempan, err = expint.New((*expint.Config)(&p.config.ExpInt))
	if err != nil {
		return nil, err
	}

	p.interp = adhier.New(newcot.New(p.inputs), linhat.New(p.inputs), p.outputs)

	return p, nil
}

func (p *problem) solve() error {
	p.interp.Construct(p.evaluate)
	return nil
}

func (p *problem) evaluate(nodes []float64) []float64 {
	sched := p.time.Compute(p.priority)

	P := p.power.Compute(sched)

	steps := uint16(len(P)) / p.cores

	Q := make([]float64, p.cores*steps)

	p.tempan.ComputeTransient(P, Q, uint32(p.cores), uint32(steps))

	return Q
}
