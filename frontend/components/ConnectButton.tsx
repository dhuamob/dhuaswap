"use client"
import { useAccount, useConnect, useDisconnect } from 'wagmi'

export default function ConnectButton() {
  const { address, isConnected } = useAccount()
  const { connect } = useConnect()
  const { disconnect } = useDisconnect()

  if (isConnected) {
    return (
      <div className="flex items-center gap-4">
        <span className="text-sm">{address}</span>
        <button className="px-3 py-1 bg-gray-200 rounded" onClick={() => disconnect()}>
          Disconnect
        </button>
      </div>
    )
  }

  const handleConnect = async () => {
    // Dynamically import the injected connector on click so the module isn't
    // evaluated during server-side rendering.
    const { injected } = await import('@wagmi/connectors')
    connect({ connector: injected() })
  }

  return (
    <button className="px-4 py-2 bg-blue-600 text-white rounded" onClick={handleConnect}>
      Connect Wallet
    </button>
  )
}
