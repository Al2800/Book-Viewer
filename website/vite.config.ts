import {execFileSync} from 'node:child_process'
import vinext from 'vinext'
import {defineConfig} from 'vite'
import {sites} from './sites-vite-plugin'

function sourceRevision(): string {
  const environmentRevision =
    process.env.GITHUB_SHA ?? process.env.CF_PAGES_COMMIT_SHA ?? process.env.SOURCE_REVISION
  if (environmentRevision) return environmentRevision.slice(0, 12)

  try {
    return execFileSync('git', ['rev-parse', '--short=12', 'HEAD'], {encoding: 'utf8'}).trim()
  } catch {
    return 'unknown'
  }
}

const localBindingConfig = {
  main: './worker/index.ts',
  compatibility_flags: ['nodejs_compat'],
}

export default defineConfig(async () => {
  process.env.WRANGLER_WRITE_LOGS ??= 'false'
  process.env.WRANGLER_LOG_PATH ??= '.wrangler/logs'
  process.env.MINIFLARE_REGISTRY_PATH ??= '.wrangler/registry'

  const {cloudflare} = await import('@cloudflare/vite-plugin')

  return {
    define: {
      __BOOKQUOTES_SOURCE_REVISION__: JSON.stringify(sourceRevision()),
    },
    plugins: [
      vinext(),
      sites(),
      cloudflare({
        viteEnvironment: {name: 'rsc', childEnvironments: ['ssr']},
        config: localBindingConfig,
      }),
    ],
  }
})
