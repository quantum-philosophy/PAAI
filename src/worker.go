package main

// #include <string.h>
import "C"

import (
	"unsafe"

	"github.com/go-math/linal/matrix"
)

type worker struct {
	p *problem

	P []float64
	S []float64

	z []float64
	u []float64
	d []float64
}

type job struct {
	id  uint32
	key string

	node []float64
	data []float64

	done chan result
}

type result struct {
	id  uint32
	key string

	data []float64
}

func newWorker(p *problem) *worker {
	return &worker{
		p: p,

		P: make([]float64, p.cc*p.sc),
		S: make([]float64, p.tempan.Nodes*p.sc),

		z: make([]float64, p.zc),
		u: make([]float64, p.uc),
		d: make([]float64, p.tc),
	}
}

func (w *worker) serve(jobs chan job) {
	for job := range jobs {
		job.done <- result{job.id, job.key, w.compute(job.node, job.data)}
	}
}

func (w *worker) compute(node, Q []float64) []float64 {
	p := w.p
	cc, sc, uc, zc := p.cc, p.sc, p.uc, p.zc

	if Q == nil {
		Q = make([]float64, cc*sc)
	}

	// Independent uniform to independent Gaussian
	for i := uint32(0); i < zc; i++ {
		w.z[i] = p.gaussian.InvCDF(node[i])
	}

	// Independent Gaussian to dependent Gaussian
	matrix.Multiply(p.trans, w.z, w.u, uc, zc, 1)

	// Dependent Gaussian to dependent uniform to dependent target
	for i, tid := range p.config.TaskIndex {
		w.d[tid] = p.margins[i].InvCDF(p.gaussian.CDF(w.u[i]))
	}

	// FIXME: Bad, bad, bad!
	C.memset(unsafe.Pointer(&w.P[0]), 0, C.size_t(8*cc*sc))
	p.power.Compute(p.time.Recompute(p.sched, w.d), w.P, sc)

	p.tempan.ComputeTransient(w.P, Q, w.S, sc)

	return Q
}
