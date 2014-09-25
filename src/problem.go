package main

import (
	"fmt"

	"github.com/go-eslab/persim/power"
	"github.com/go-eslab/persim/system"
	"github.com/go-eslab/persim/time"
	"github.com/go-eslab/tempan/expint"

	"github.com/go-math/numan/basis/linhat"
	"github.com/go-math/numan/grid/newcot"
	"github.com/go-math/numan/interp/adhier"
	"github.com/go-math/prob/beta"
	"github.com/go-math/prob/gaussian"
	"github.com/go-math/stats/corr"
)

const (
	cacheCapacity = 1000
)

type problem struct {
	config Config

	cc uint32 // cores
	tc uint32 // tasks

	time   *time.List
	power  *power.Self
	tempan *expint.Self

	sc uint32 // steps

	sched *time.Schedule

	uc uint32 // dependent variables
	zc uint32 // independent variables

	margins  []*beta.Self
	gaussian *gaussian.Self
	trans    []float64

	ic uint32 // inputs
	oc uint32 // outputs

	interp *adhier.Self

	worker *worker
	cache  *cache
}

func (p *problem) String() string {
	return fmt.Sprintf("Problem{cores: %d, tasks: %d, steps: %d, dvars: %d, ivars: %d, inputs: %d, outputs: %d}",
		p.cc, p.tc, p.sc, p.uc, p.zc, p.ic, p.oc)
}

func newProblem(config Config) (*problem, error) {
	var err error

	p := &problem{config: config}
	c := &p.config

	plat, app, err := system.Load(c.TGFF)
	if err != nil {
		return nil, err
	}

	p.cc = uint32(len(plat.Cores))
	p.tc = uint32(len(app.Tasks))

	if len(c.CoreIndex) == 0 {
		c.CoreIndex = make([]uint16, p.cc)
		for i := uint16(0); i < uint16(p.cc); i++ {
			c.CoreIndex[i] = i
		}
	}
	if len(c.TaskIndex) == 0 {
		c.TaskIndex = make([]uint16, p.tc)
		for i := uint16(0); i < uint16(p.tc); i++ {
			c.TaskIndex[i] = i
		}
	}

	p.time = time.NewList(plat, app)
	p.power = power.New(plat, app, c.Analysis.TimeStep)
	p.tempan, err = expint.New(expint.Config(c.Analysis))
	if err != nil {
		return nil, err
	}

	p.sched = p.time.Compute(system.NewProfile(plat, app).Mobility)

	p.sc = uint32(p.sched.Span / c.Analysis.TimeStep)

	p.uc = uint32(len(c.TaskIndex))

	C := correlate(app, c.TaskIndex, c.ProbModel.CorrLength)
	p.trans, p.zc, err = corr.Decompose(C, p.uc, c.ProbModel.VarThreshold)
	if err != nil {
		return nil, err
	}

	p.margins = make([]*beta.Self, p.uc)
	for i, tid := range c.TaskIndex {
		delay := c.ProbModel.MaxDelay * plat.Cores[p.sched.Mapping[tid]].Time[app.Tasks[tid].Type]
		p.margins[i] = beta.New(c.ProbModel.Alpha, c.ProbModel.Beta, 0, delay)
	}

	p.gaussian = gaussian.New(0, 1)

	p.ic = p.zc + 1 // +1 for time
	p.oc = uint32(len(c.CoreIndex))

	p.interp = adhier.New(newcot.New(uint16(p.ic)), linhat.New(uint16(p.ic)),
		adhier.Config(c.Interpolation), uint16(p.oc))

	p.worker = newWorker(p)
	p.cache = newCache(p.zc, cacheCapacity)

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

	Q := make([]float64, cc*sc)
	values := make([]float64, p.oc*nc)

	for i, k := uint32(0), uint32(0); i < nc; i++ {
		sid := uint32(nodes[i*ic] * float64(sc-1))

		p.worker.compute(nodes[i*ic+1:], Q)

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

	for i, k := uint32(0), uint32(0); i < nc; i++ {
		sid := uint32(nodes[i*ic] * float64(sc-1))

		Q := p.cache.fetch(index[i*ic+1:], func() []float64 {
			Q := make([]float64, cc*sc)
			p.worker.compute(nodes[i*ic+1:], Q)
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
