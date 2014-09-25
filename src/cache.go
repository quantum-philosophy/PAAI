package main

import (
	"fmt"
	"unsafe"
)

// No cuncurrent access for now!
type cache struct {
	hc uint32
	mc uint32

	length uint32
	buffer []byte

	storage map[string][]float64
}

func (c *cache) String() string {
	return fmt.Sprintf("Cache{hits: %d (%.2f%%), misses: %d (%.2f%%)}",
		c.hc, float64(c.hc)/float64(c.hc+c.mc)*100,
		c.mc, float64(c.mc)/float64(c.hc+c.mc)*100)
}

func newCache(length uint32, space uint32) *cache {
	return &cache{
		length:  length,
		buffer:  make([]byte, 8*length),
		storage: make(map[string][]float64, space),
	}
}

func (c *cache) fetch(sequence []uint64, compute func() []float64) (value []float64) {
	for i := uint32(0); i < c.length; i++ {
		*(*uint64)(unsafe.Pointer(&c.buffer[8*i])) = sequence[i]
	}

	key := string(c.buffer)
	value = c.storage[key]

	if value != nil {
		c.hc++
		return
	}

	c.mc++

	value = compute()
	c.storage[key] = value

	return
}
