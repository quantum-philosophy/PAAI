package main

import (
	"errors"
	"fmt"
	"runtime"

	"github.com/go-eslab/persim/power"
	"github.com/go-eslab/persim/system"
	"github.com/go-eslab/persim/time"
	"github.com/go-eslab/tempan/expint"

	"github.com/go-math/numan/basis/linhat"
	"github.com/go-math/numan/grid/newcot"
	"github.com/go-math/numan/interp/adhier"
	"github.com/go-math/prob"
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

	marginals []prob.Inverter
	gaussian  prob.Distribution
	trans     []float64

	ic uint32 // inputs
	oc uint32 // outputs

	interp *adhier.Self

	cache *cache
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

	p.marginals = make([]prob.Inverter, p.uc)
	marginalizer := marginalize(c.ProbModel.Marginal)
	if marginalizer == nil {
		return nil, errors.New("invalid marginal distributions")
	}
	for i, tid := range c.TaskIndex {
		delay := c.ProbModel.MaxDelay * plat.Cores[p.sched.Mapping[tid]].Time[app.Tasks[tid].Type]
		p.marginals[i] = marginalizer(delay)
	}

	p.gaussian = gaussian.New(0, 1)

	p.ic = p.zc + 1 // +1 for time
	p.oc = uint32(len(c.CoreIndex))

	p.interp = adhier.New(newcot.NewOpen(uint16(p.ic)), linhat.NewOpen(uint16(p.ic)),
		adhier.Config(c.Interpolation), uint16(p.oc))

	p.cache = newCache(p.zc, cacheCapacity)

	return p, nil
}

func (p *problem) solve() *adhier.Surrogate {
	cc, sc, ic, oc := p.cc, p.sc, p.ic, p.oc
	cache, coreIndex := p.cache, p.config.CoreIndex

	jobs := p.spawnWorkers()

	surrogate := p.interp.Compute(func(nodes []float64, index []uint64) []float64 {
		nc := uint32(len(nodes)) / ic
		if p.config.Verbose {
			fmt.Printf("%d ", nc)
		}

		results := make(chan result, nc)
		values := make([]float64, oc*nc)

		for i := uint32(0); i < nc; i++ {
			key := cache.key(index[i*ic+1:])

			if Q := cache.get(key); Q == nil {
				jobs <- job{i, key, nodes[i*ic+1:], results}
			} else {
				results <- result{i, key, Q}
			}
		}

		for i := uint32(0); i < nc; i++ {
			result := <-results

			k, Q := result.id, result.Q
			sid := uint32(nodes[k*ic] * float64(sc-1))

			for j := uint32(0); j < oc; j++ {
				values[k*oc+j] = Q[sid*cc+uint32(coreIndex[j])]
			}

			cache.set(result.key, Q)
		}

		return values
	})

	close(jobs)

	return surrogate
}

func (p *problem) compute(nodes []float64) []float64 {
	cc, sc, ic, oc := p.cc, p.sc, p.ic, p.oc
	coreIndex := p.config.CoreIndex

	jobs := p.spawnWorkers()

	nc := uint32(len(nodes)) / ic
	if p.config.Verbose {
		fmt.Printf("%d ", nc)
	}

	results := make(chan result, nc)
	values := make([]float64, p.oc*nc)

	jc, rc := uint32(0), uint32(0)
	nextJob := job{id: jc, node: nodes[jc*ic+1:], done: results}

	for jc < nc || rc < nc {
		select {
		case jobs <- nextJob:
			jc++

			if jc >= nc {
				close(jobs)
				jobs = nil
				continue
			}

			nextJob = job{id: jc, node: nodes[jc*ic+1:], done: results}
		case result := <-results:
			rc++

			k, Q := result.id, result.Q
			sid := uint32(nodes[k*ic] * float64(sc-1))

			for j := uint32(0); j < oc; j++ {
				values[k*oc+j] = Q[sid*cc+uint32(coreIndex[j])]
			}
		}
	}

	return values
}

func (p *problem) evaluate(s *adhier.Surrogate, points []float64) []float64 {
	return p.interp.Evaluate(s, points)
}

func (p *problem) spawnWorkers() chan job {
	wc := int(p.config.Workers)
	if wc <= 0 {
		wc = runtime.NumCPU()
	}

	if p.config.Verbose {
		fmt.Printf("Using %d workers...\n", wc)
	}

	runtime.GOMAXPROCS(wc)

	jobs := make(chan job)
	for i := 0; i < wc; i++ {
		go serve(p, jobs)
	}

	return jobs
}
