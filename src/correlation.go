package main

import (
	"math"

	"github.com/go-eslab/persim/system"
)

func correlate(app *system.Application, index []uint16, length float64) []float64 {
	tc, dc := uint16(len(app.Tasks)), uint16(len(index))
	steps := explore(app)

	corr := make([]float64, dc*dc)

	for i := uint16(0); i < dc; i++ {
		corr[i*dc+i] = 1
		for j := i + 1; j < dc; j++ {
			f, t := index[i], index[j]

			s := steps[t*tc+f]
			if s == 0 {
				s = steps[f*tc+t]
			}
			if s == 0 {
				s = ascendDescend(app, f, t, steps)
			}
			if s == 0 {
				panic("should have found a path")
			}

			ρ := math.Exp(-float64(s) / length)

			corr[j*dc+i] = ρ
			corr[i*dc+j] = ρ
		}
	}

	return corr
}

func explore(app *system.Application) []uint16 {
	tc := uint16(len(app.Tasks))
	steps := make([]uint16, tc*tc)

	for i := uint16(0); i < tc; i++ {
		for j := i + 1; j < tc; j++ {
			if s := ascend(app, j, i); s > 0 {
				steps[j*tc+i] = s
			} else {
				steps[i*tc+j] = ascend(app, i, j)
			}
		}
	}

	return steps
}

// ascend returns the minimal number of steps to climb up from f to t. The
// function assumes f ≠ t and returns 0 if no path was found.
func ascend(app *system.Application, f, t uint16) uint16 {
	min := uint16(0)

	for _, p := range app.Tasks[f].Parents {
		if t == p {
			return 1
		} else if s := ascend(app, p, t); s > 0 && (min == 0 || s < min) {
			min = s
		}
	}

	if min == 0 {
		return 0
	} else {
		return min + 1
	}
}

// ascendDescend returns the minimal number of steps to climb down from the
// ancestors of f to t. The function assumes f ≠ t and returns 0 if no path was
// found.
func ascendDescend(app *system.Application, f, t uint16, steps []uint16) uint16 {
	tc, min := uint16(len(app.Tasks)), uint16(0)

	for _, p := range app.Tasks[f].Parents {
		if s := steps[t*tc+p]; s > 0 && (min == 0 || s < min) {
			min = s
		} else if s := ascendDescend(app, p, t, steps); s > 0 && (min == 0 || s < min) {
			min = s
		}
	}

	if min == 0 {
		return 0
	} else {
		return min + 1
	}
}
