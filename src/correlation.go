package main

import (
	"math"

	"github.com/go-eslab/persim/system"
)

func correlate(app *system.Application, length float64) []float64 {
	tc := uint16(len(app.Tasks))
	corr := make([]float64, tc*tc)

	for i := uint16(0); i < tc; i++ {
		corr[i*tc+i] = 1
		for j := i + 1; j < tc; j++ {
			steps := ascend(app, j, i)
			if steps < 0 {
				steps = ascend(app, i, j)
			}
			if steps < 0 {
				continue
			}
			ρ := math.Exp(-steps / length)
			corr[j*tc+i] = ρ
			corr[i*tc+j] = ρ
		}
	}

	return corr
}

func ascend(app *system.Application, f, t uint16) float64 {
	if f == t {
		return 0
	}

	found := 0
	steps := float64(0)

	for _, p := range app.Tasks[f].Parents {
		if s := ascend(app, p, t); s >= 0 {
			steps += s
			found++
		}
	}

	if found > 0 {
		return steps/float64(found) + 1
	} else {
		return -1
	}
}
