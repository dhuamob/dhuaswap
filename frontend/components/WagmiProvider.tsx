"use client"
import { ReactNode } from 'react'
import dynamic from 'next/dynamic'

const WagmiConfigWrapper = dynamic(
  () => import('./WagmiConfigWrapper'),
  { ssr: false }
)

export default function WagmiProvider({ children }: { children: ReactNode }) {
  return <WagmiConfigWrapper>{children}</WagmiConfigWrapper>
}
