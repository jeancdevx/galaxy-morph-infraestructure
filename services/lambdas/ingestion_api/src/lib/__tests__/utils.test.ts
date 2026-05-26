import { describe, expect, it } from 'vitest'

import { chunk, endOfDayTtlSeconds } from '../../lib/utils.js'

describe('chunk', () => {
  it('splits array into batches of given size', () => {
    expect(chunk([1, 2, 3, 4, 5], 2)).toEqual([[1, 2], [3, 4], [5]])
  })

  it('returns single batch when array is smaller than size', () => {
    expect(chunk([1, 2], 10)).toEqual([[1, 2]])
  })

  it('returns empty array for empty input', () => {
    expect(chunk([], 5)).toEqual([])
  })
})

describe('endOfDayTtlSeconds', () => {
  it('returns a Unix timestamp greater than current time', () => {
    const ttl = endOfDayTtlSeconds()
    expect(ttl).toBeGreaterThan(Math.floor(Date.now() / 1000))
  })

  it('returns a TTL that is at most 24 hours from now', () => {
    const ttl = endOfDayTtlSeconds()
    const now = Math.floor(Date.now() / 1000)
    expect(ttl - now).toBeLessThanOrEqual(86400)
  })
})
