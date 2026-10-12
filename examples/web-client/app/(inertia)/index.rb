# frozen_string_literal: true

def admin_nodes
  costs = Cost.snapshot

  {
    nodes: Kube.node_stats.map { |node| node.merge(cost: costs&.dig(:nodes, node[:name])) },
    pods:  Kube.pod_rows.map { |pod| pod.merge(cost: costs&.dig(:pods, "#{pod[:namespace]}/#{pod[:name]}")) },
    error: nil,
  }
rescue Kube::Error => e
  { nodes: [], pods: [], error: e.message }
end

get "/" do
  render("index", **admin_nodes)
end

__END__

import { Head, usePoll } from "@inertiajs/react"

import NodeUsage, { type Node, type Pod } from "@/components/node-usage"
import { ShellHeader } from "@/components/admin/slots"

export default function AdminIndex({
  nodes,
  pods,
  error,
}: {
  nodes: Node[]
  pods: Pod[]
  error: string | null
}) {
  usePoll(5000, { only: ["nodes", "pods", "error"] })

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Admin" />

      <ShellHeader>
        <h1 className="font-medium">Admin</h1>
        <p className="text-muted-foreground hidden min-w-0 truncate text-sm lg:block">
          Resource usage of the cluster nodes, refreshed every five seconds.
        </p>
      </ShellHeader>

      <div className="flex min-h-0 flex-1 flex-col gap-6 overflow-y-auto">
        {error && (
          <p className="text-muted-foreground mx-4 mt-4 rounded-lg border p-4 text-sm">
            The cluster is not answering: <span className="font-mono text-xs">{error}</span>
          </p>
        )}

        <NodeUsage nodes={nodes} pods={pods} />
      </div>
    </div>
  )
}
