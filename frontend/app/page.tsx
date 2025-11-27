import dynamic from 'next/dynamic'

const ConnectButton = dynamic(() => import('../components/ConnectButton'), { ssr: false })

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <h1 className="text-4xl font-bold">DhuaSwap</h1>
      <p className="mt-4 text-lg">Decentralized Exchange</p>
      <div className="mt-6">
        <ConnectButton />
      </div>
    </main>
  )
}

