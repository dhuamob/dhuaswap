// @ts-nocheck
"use client"
// Minimal wagmi client setup. This file exports a wagmi config and an injected connector
// so the app can use the installed wagmi/viem runtime. Kept intentionally small.
import { createConfig } from 'wagmi'
import { injected } from '@wagmi/connectors'
import { createPublicClient, http } from 'viem'
import { sepolia } from 'viem/chains'

// Create a viem public client for Sepolia (used for read-only calls)
const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(),
})

let wagmiConfig: ReturnType<typeof createConfig> | null = null

export function getWagmiConfig() {
  if (!wagmiConfig) {
    wagmiConfig = createConfig({
      connectors: [injected()],
      publicClient,
    })
  }
  return wagmiConfig
}
