package main

// #include <string.h>
import "C"

import (
	"errors"
	"fmt"
	"math"
	"unsafe"

	"github.com/go-eslab/persim/power"
	"github.com/go-eslab/persim/system"
	"github.com/go-eslab/persim/time"
	"github.com/go-eslab/tempan/expint"

	"github.com/go-math/numan/basis/linhat"
	"github.com/go-math/numan/grid/newcot"
	"github.com/go-math/numan/interp/adhier"
	"github.com/go-math/stats/corr"
)

const (
	cacheCapacity = 1000
)

type problem struct {
	config Config

	cc uint32 // cores
	tc uint32 // tasks
	sc uint32 // steps
	ic uint32 // inputs
	oc uint32 // outputs

	time   *time.List
	power  *power.Self
	tempan *expint.Self
	interp *adhier.Self

	sched *time.Schedule
	delay []float64
	trans []float64

	cache *cache
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
	c := &p.config

	plat, app, err := system.Load(c.TGFF)
	if err != nil {
		return nil, err
	}

	p.time = time.NewList(plat, app)
	p.sched = p.time.Compute(system.NewProfile(plat, app).Mobility)
	p.power = power.New(plat, app, c.Analysis.TimeStep)

	p.cc = uint32(len(plat.Cores))
	if len(c.CoreIndex) == 0 {
		c.CoreIndex = make([]uint16, p.cc)
		for i := uint16(0); i < uint16(p.cc); i++ {
			c.CoreIndex[i] = i
		}
	}

	p.tc = uint32(len(app.Tasks))
	if len(c.TaskIndex) == 0 {
		c.TaskIndex = make([]uint16, p.tc)
		for i := uint16(0); i < uint16(p.tc); i++ {
			c.TaskIndex[i] = i
		}
	}

	p.sc = uint32(p.sched.Span / c.Analysis.TimeStep)
	p.ic = uint32(len(c.TaskIndex)) // not final!
	p.oc = uint32(len(c.CoreIndex))

	Σ := correlate(app, c.TaskIndex, c.CorrLength)
	p.trans, p.ic, err = corr.Decompose(Σ, p.ic, c.VarThreshold)
	if err != nil {
		return nil, err
	}

	p.ic += 1 // +1 for time

	if err = p.validate(); err != nil {
		return nil, err
	}

	p.delay = make([]float64, p.tc)
	for i := range p.delay {
		p.delay[i] = c.DelayRate * plat.Cores[p.sched.Mapping[i]].Time[app.Tasks[i].Type]
	}

	p.tempan, err = expint.New(expint.Config(c.Analysis))
	if err != nil {
		return nil, err
	}

	p.interp = adhier.New(newcot.New(uint16(p.ic)), linhat.New(uint16(p.ic)),
		adhier.Config(c.Interpolation), uint16(p.oc))

	p.cache = newCache(p.ic-1, cacheCapacity) // -1 for time

	return p, nil
}

func (p *problem) solve() *adhier.Surrogate {
	return p.interp.Compute(p.fetch)
}

func (p *problem) compute(nodes []float64, _ []uint64) []float64 {
	cc, sc, ic := p.cc, p.sc, p.ic
	nc := uint32(len(nodes)) / ic

	if p.config.Verbose {
		fmt.Printf("%d ", nc)
	}

	values := make([]float64, p.oc*nc)
	delay := make([]float64, p.tc)

	P := make([]float64, cc*sc)
	Q := make([]float64, cc*sc)
	S := make([]float64, p.tempan.Nodes*sc)

	for i, k := uint32(0), uint32(0); i < nc; i++ {
		sid := uint32(nodes[i*ic] * float64(sc-1))

		for j, tid := range p.config.TaskIndex {
			delay[tid] = nodes[i*ic+1+uint32(j)] * p.delay[tid]
		}

		// FIXME: Bad, bad, bad!
		C.memset(unsafe.Pointer(&P[0]), 0, C.size_t(8*cc*sc))

		p.power.Compute(p.time.Recompute(p.sched, delay), P, sid+1)
		p.tempan.ComputeTransient(P, Q, S, sid+1)

		for _, cid := range p.config.CoreIndex {
			values[k] = Q[sid*cc+uint32(cid)]
			k++
		}
	}

	return values
}

func (p *problem) fetch(nodes []float64, index []uint64) []float64 {
	cc, sc, ic := p.cc, p.sc, p.ic
	nc := uint32(len(nodes)) / ic

	if p.config.Verbose {
		fmt.Printf("%d ", nc)
	}

	values := make([]float64, p.oc*nc)
	delay := make([]float64, p.tc)

	P := make([]float64, cc*sc)
	S := make([]float64, p.tempan.Nodes*sc)

	for i, k := uint32(0), uint32(0); i < nc; i++ {
		sid := uint32(nodes[i*ic] * float64(sc-1))

		Q := p.cache.fetch(index[i*ic+1:], func() []float64 {
			for j, tid := range p.config.TaskIndex {
				delay[tid] = nodes[i*ic+1+uint32(j)] * p.delay[tid]
			}

			Q := make([]float64, cc*sc)

			// FIXME: Bad, bad, bad!
			C.memset(unsafe.Pointer(&P[0]), 0, C.size_t(8*cc*sc))

			p.power.Compute(p.time.Recompute(p.sched, delay), P, sc)
			p.tempan.ComputeTransient(P, Q, S, sc)

			return Q
		})

		for _, cid := range p.config.CoreIndex {
			values[k] = Q[sid*cc+uint32(cid)]
			k++
		}
	}

	return values
}

func (p *problem) evaluate(s *adhier.Surrogate, points []float64) []float64 {
	return p.interp.Evaluate(s, points)
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

	if p.config.Interpolation.AbsError <= 0 {
		return errors.New("the absolute-error tolerance is invalid")
	}
	if p.config.Interpolation.RelError <= 0 {
		return errors.New("the relative-error tolerance is invalid")
	}

	return nil
}
