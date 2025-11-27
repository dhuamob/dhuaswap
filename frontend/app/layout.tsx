import './globals.css'
import type { Metadata } from 'next'
import dynamic from 'next/dynamic'

const WagmiProvider = dynamic(() => import('../components/WagmiProvider'), {
  ssr: false,
})

export const metadata: Metadata = {
  title: 'DhuaSwap',
  description: 'A decentralized exchange',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>
        <WagmiProvider>{children}</WagmiProvider>
      </body>
    </html>
  )
}

