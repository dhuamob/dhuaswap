"use client"
// Lightweight wagmi wiring. We use `any` in places to avoid strict type issues
// in the current workspace and focus on runtime behavior.
import { InjectedConnector } from 'wagmi/connectors/injected'
import { configureChains, createConfig } from 'wagmi'
import { mainnet, sepolia } from 'viem/chains'
import { publicProvider } from 'wagmi/providers/public'

const chains: any = [sepolia, mainnet]
const providers: any = [publicProvider()]

const { publicClient }: any = configureChains(chains, providers)

export const wagmiConfig: any = createConfig({
  autoConnect: true,
  publicClient,
})

export const injectedConnector: any = new InjectedConnector()
