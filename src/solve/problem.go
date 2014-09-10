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

	cc uint32
	tc uint32
	sc uint32
	ic uint32
	oc uint32

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

	p.cc = uint32(len(plat.Cores))
	p.tc = uint32(len(app.Tasks))
	p.sc = uint32(math.Floor(p.schedule.Span() / p.config.TimeStep))
	p.ic = uint32(len(p.config.TaskIndex))
	p.oc = uint32(len(p.config.CoreIndex)) * p.sc

	if len(p.config.StepIndex) == 0 {
		p.config.StepIndex = make([]uint32, p.sc / uint32(p.config.StepThinning))
		for i := range p.config.StepIndex {
			p.config.StepIndex[i] = uint32(i) * uint32(p.config.StepThinning)
		}
	}

	if err = p.validate(); err != nil {
		return nil, err
	}

	p.delay = make([]float64, p.tc)
	for i := range p.delay {
		p.delay[i] = p.config.DelayRate * (p.schedule.Finish[i] - p.schedule.Start[i])
	}

	p.tempan, err = expint.New((*expint.Config)(&p.config.TempConfig))
	if err != nil {
		return nil, err
	}

	p.interp = adhier.New(newcot.New(uint16(p.ic)), linhat.New(uint16(p.ic)), uint16(p.oc))

	return p, nil
}

func (p *problem) solve() *adhier.Surrogate {
	return p.interp.Compute(p.evaluate)
}

func (p *problem) evaluate(nodes []float64) []float64 {
	nc := uint32(len(nodes)) / p.ic

	values := make([]float64, uint32(p.oc)*nc)

	delay := make([]float64, p.tc)
	P := make([]float64, p.cc*p.sc)
	Q := make([]float64, len(P))

	var k uint32

	for i := uint32(0); i < nc; i++ {
		for j, tid := range p.config.TaskIndex {
			// NOTE: nodes contains values in the interval [0, 1].
			delay[tid] = nodes[i*p.ic+uint32(j)] * p.delay[tid]
		}

		p.power.Compute(p.time.Recompute(p.schedule, delay), P, p.sc)
		p.tempan.ComputeTransient(P, Q, p.sc)

		for _, sid := range p.config.StepIndex {
			for _, cid := range p.config.CoreIndex {
				values[k] = Q[sid*p.cc+uint32(cid)]
				k++
			}
		}
	}

	return values
}

func (p *problem) validate() error {
	if p.sc >= math.MaxUint16 {
		return errors.New("the number of steps is too large")
	}

	if p.ic >= math.MaxUint16 {
		return errors.New("the number of inputs is too large")
	}

	if p.oc >= math.MaxUint16 {
		return errors.New("the number of outputs is too large")
	}

	if len(p.config.CoreIndex) == 0 {
		return errors.New("the core index is empty")
	}

	for _, cid := range p.config.CoreIndex {
		if uint32(cid) >= p.cc {
			return errors.New("the core index is invalid")
		}
	}

	if len(p.config.TaskIndex) == 0 {
		return errors.New("the task index is empty")
	}

	for _, tid := range p.config.TaskIndex {
		if uint32(tid) >= p.tc {
			return errors.New("the task index is invalid")
		}
	}

	if len(p.config.StepIndex) == 0 {
		return errors.New("the step index is empty")
	}

	for _, sid := range p.config.StepIndex {
		if sid >= p.sc {
			return errors.New("the step index is invalid")
		}
	}

	return nil
}
