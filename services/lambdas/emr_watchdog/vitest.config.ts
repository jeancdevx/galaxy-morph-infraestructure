import path from 'path'

import { defineConfig } from 'vitest/config'

export default defineConfig({
  resolve: {
    alias: {
      '@galaxy-morph/shared': path.resolve(
        __dirname,
        '../../shared/src/index.ts'
      )
    }
  },
  test: {
    environment: 'node',
    coverage: {
      provider: 'v8',
      include: ['src/services/**', 'src/lib/**'],
      exclude: ['src/lib/powertools.ts', 'src/lib/clients.ts'],
      thresholds: { lines: 70, functions: 70, branches: 70 }
    }
  }
})
