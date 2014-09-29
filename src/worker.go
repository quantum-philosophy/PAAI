package main

// #include <string.h>
import "C"

import (
	"unsafe"

	"github.com/go-math/linal/matrix"
)

type job struct {
	id   uint32
	key  string
	node []float64
	done chan<- result
}

type result struct {
	id  uint32
	key string
	Q   []float64
}

func serve(p *problem, jobs <-chan job) {
	cc, sc, uc, zc := p.cc, p.sc, p.uc, p.zc

	g, m := p.gaussian, p.marginals

	P := make([]float64, cc*sc)
	S := make([]float64, p.tempan.Nodes*sc)

	z := make([]float64, zc)
	u := make([]float64, uc)
	d := make([]float64, p.tc)

	for job := range jobs {
		Q := make([]float64, cc*sc)

		// Independent uniform to independent Gaussian
		for i := uint32(0); i < zc; i++ {
			z[i] = g.InvCDF(job.node[i])
		}

		// Independent Gaussian to dependent Gaussian
		matrix.Multiply(p.trans, z, u, uc, zc, 1)

		// Dependent Gaussian to dependent uniform to dependent target
		for i, tid := range p.config.TaskIndex {
			d[tid] = m[i].InvCDF(g.CDF(u[i]))
		}

		// FIXME: Bad, bad, bad!
		C.memset(unsafe.Pointer(&P[0]), 0, C.size_t(8*cc*sc))

		p.power.Compute(p.time.Recompute(p.sched, d), P, sc)
		p.tempan.ComputeTransient(P, Q, S, sc)

		job.done <- result{job.id, job.key, Q}
	}
}
