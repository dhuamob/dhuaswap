"use client"
import { useEffect, useState } from 'react'

function ConnectButton() {
  const [address, setAddress] = useState<string | null>(null)

  useEffect(() => {
    if ((window as any).ethereum && (window as any).ethereum.selectedAddress) {
      setAddress((window as any).ethereum.selectedAddress)
    }
  }, [])

  async function connect() {
    try {
      if (!(window as any).ethereum) {
        alert('No injected wallet found (e.g. MetaMask)')
        return
      }
      const accounts: string[] = await (window as any).ethereum.request({ method: 'eth_requestAccounts' })
      setAddress(accounts[0])
    } catch (err) {
      console.error('wallet connect failed', err)
    }
  }

  function disconnect() {
    // Can't programmatically disconnect many injected wallets; just clear UI state
    setAddress(null)
  }

  if (address) {
    return (
      <div className="flex items-center gap-4">
        <span className="text-sm">{address}</span>
        <button className="px-3 py-1 bg-gray-200 rounded" onClick={disconnect}>
          Disconnect
        </button>
      </div>
    )
  }

  return (
    <button className="px-4 py-2 bg-blue-600 text-white rounded" onClick={connect}>
      Connect Wallet
    </button>
  )
}

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

