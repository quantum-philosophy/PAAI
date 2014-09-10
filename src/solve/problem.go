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

	cc uint16
	tc uint16
	sc uint16
	ic uint16
	oc uint16

	priority []float64
	time     *time.List
	schedule *time.Schedule
	power    *power.Self
	delay    []float64

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
	p.schedule = p.time.Compute(p.priority)
	p.power = power.New(plat, app, p.config.TimeStep)

	p.cc = uint16(len(plat.Cores))
	p.tc = uint16(len(app.Tasks))

	if count := math.Floor(p.schedule.Span() / p.config.TimeStep); count > math.MaxUint16 {
		return nil, errors.New("the number of steps is too large")
	} else {
		p.sc = uint16(count)
	}

	p.ic = uint16(len(p.config.TaskIndex))

	if count := uint32(len(p.config.CoreIndex)) * uint32(p.sc); count > math.MaxUint16 {
		return nil, errors.New("the number of outputs is too large")
	} else {
		p.oc = uint16(count)
	}

	p.delay = make([]float64, p.tc)
	for i := range p.delay {
		p.delay[i] = p.config.DelayRate * (p.schedule.Finish[i] - p.schedule.Start[i])
	}

	p.tempan, err = expint.New((*expint.Config)(&p.config.ExpInt))
	if err != nil {
		return nil, err
	}

	p.interp = adhier.New(newcot.New(p.ic), linhat.New(p.ic), p.oc)

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

	sc := uint16(len(P)) / p.cc

	Q := make([]float64, p.cc*sc)

	p.tempan.ComputeTransient(P, Q, uint32(p.cc), uint32(sc))

	return Q
}

func (p *problem) validate() error {
	if len(p.config.CoreIndex) == 0 {
		return errors.New("the core index is empty")
	}

	for _, id := range p.config.CoreIndex {
		if id >= p.cc {
			return errors.New("the core index is invalid")
		}
	}

	if len(p.config.TaskIndex) == 0 {
		return errors.New("the task index is empty")
	}

	for _, id := range p.config.TaskIndex {
		if id >= p.tc {
			return errors.New("the task index is invalid")
		}
	}

	return nil
}
