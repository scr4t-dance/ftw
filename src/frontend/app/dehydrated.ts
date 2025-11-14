// Taken from https://github.com/maplegrove-io/use-dehydrated-state
import type { DehydratedState } from '@tanstack/react-query'

import merge from 'deepmerge'

import { useMatches } from 'react-router'

export function useDehydratedState(): DehydratedState | undefined {
  const matches = useMatches()

  const dehydratedState = matches
    .map((match) => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      return (match.loaderData as any)?.dehydratedState
    })
    .filter(Boolean)

  return dehydratedState.length
    ? dehydratedState.reduce((accumulator, currentValue) => merge(accumulator, currentValue), {})
    : undefined
}