package main

import (
	"errors"
	"fmt"
	"math"
	"math/rand"

	"github.com/go-eslab/persim/power"
	"github.com/go-eslab/persim/system"
	"github.com/go-eslab/persim/time"
	"github.com/go-eslab/tempan/expint"

	"github.com/go-math/numan/basis/linhat"
	"github.com/go-math/numan/grid/newcot"
	"github.com/go-math/numan/interp/adhier"
)

type problem struct {
	config Config

	cc uint32 // cores
	tc uint32 // tasks
	sc uint32 // steps
	ic uint32 // inputs
	oc uint32 // outputs

	time  *time.List
	sched *time.Schedule
	power *power.Self
	delay []float64

	tempan *expint.Self
	interp *adhier.Self
}

func (p *problem) String() string {
	return fmt.Sprintf("Problem{ cores: %d, tasks: %d, steps: %d, inputs: %d, outputs: %d }",
		p.cc, p.tc, p.sc, p.ic, p.oc)
}

func newProblem(config Config) (*problem, error) {
	var err error

	p := &problem{
		config: config,
	}

	plat, app, err := system.Load(p.config.TGFF)
	if err != nil {
		return nil, err
	}

	p.time = time.NewList(plat, app)
	p.sched = p.time.Compute(system.NewProfile(plat, app).Mobility)
	p.power = power.New(plat, app, p.config.Analysis.TimeStep)

	p.cc = uint32(len(plat.Cores))
	p.tc = uint32(len(app.Tasks))
	p.sc = uint32(math.Floor(p.sched.Span() / p.config.Analysis.TimeStep))

	if len(p.config.StepIndex) == 0 {
		p.config.StepIndex = make([]uint32, p.sc/uint32(p.config.StepThinning))
		for i := range p.config.StepIndex {
			p.config.StepIndex[i] = uint32(i) * uint32(p.config.StepThinning)
		}
	}

	p.ic = uint32(len(p.config.TaskIndex))
	p.oc = uint32(len(p.config.CoreIndex)) * uint32(len(p.config.StepIndex))

	if err = p.validate(); err != nil {
		return nil, err
	}

	p.delay = make([]float64, p.tc)
	for i := range p.delay {
		p.delay[i] = p.config.DelayRate * (p.sched.Finish[i] - p.sched.Start[i])
	}

	p.tempan, err = expint.New(expint.Config(p.config.Analysis))
	if err != nil {
		return nil, err
	}

	p.interp = adhier.New(newcot.New(uint16(p.ic)), linhat.New(uint16(p.ic)),
		adhier.Config(p.config.Interpolation), uint16(p.oc))

	return p, nil
}

func (p *problem) solve() *adhier.Surrogate {
	return p.interp.Compute(p.evaluate)
}

func (p *problem) evaluate(nodes []float64) []float64 {
	nc := uint32(len(nodes)) / p.ic

	if p.config.Verbose {
		fmt.Printf("%8d nodes\n", nc)
	}

	values := make([]float64, p.oc*nc)

	delay := make([]float64, p.tc)
	P := make([]float64, p.cc*p.sc)
	Q := make([]float64, len(P))

	var k uint32

	for i := uint32(0); i < nc; i++ {
		for j, tid := range p.config.TaskIndex {
			// NOTE: nodes contains values in the interval [0, 1].
			delay[tid] = nodes[i*p.ic+uint32(j)] * p.delay[tid]
		}

		p.power.Compute(p.time.Recompute(p.sched, delay), P, p.sc)
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

	if p.config.Interpolation.AbsError <= 0 {
		return errors.New("the absolute-error tolerance is invalid")
	}
	if p.config.Interpolation.RelError <= 0 {
		return errors.New("the relative-error tolerance is invalid")
	}

	return nil
}

func (p *problem) sample(s *adhier.Surrogate, nc uint32) ([]float64, []float64) {
	values := make([]float64, p.oc*nc)

	nodes := make([]float64, p.ic*nc)
	for i := range nodes {
		nodes[i] = rand.Float64()
	}

	p.interp.Evaluate(s, nodes)

	return values, nodes
}
