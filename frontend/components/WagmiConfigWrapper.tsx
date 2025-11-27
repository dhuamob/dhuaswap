"use client"
import { WagmiConfig } from 'wagmi'
import { getWagmiConfig } from '../lib/wagmiClient'
import { ReactNode } from 'react'

export default function WagmiConfigWrapper({ children }: { children: ReactNode }) {
  const wagmiConfig = getWagmiConfig()
  return <WagmiConfig config={wagmiConfig}>{children}</WagmiConfig>
}
