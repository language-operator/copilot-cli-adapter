# copilot-cli-adapter

The **GitHub Copilot CLI** runtime for the [Language Operator](https://github.com/language-operator/language-operator),
running as a native Kubernetes workload.

> Created from the `opencode-adapter` template. The rename is done; translating the
> operator's config into Copilot CLI's (BYOK provider, MCP servers, instructions, task
> mode) is tracked in [#1](https://github.com/language-operator/copilot-cli-adapter/issues/1).

It builds the runtime image and the Helm chart that registers the `copilot-cli`
`LanguageAgentRuntime`. The Copilot CLI TUI runs inside tmux and is fronted by an
xterm.js / WebSocket terminal in the browser, so working with the agent feels like
a real terminal session.

## Architecture

The image is [`coding-runtime`](https://github.com/language-operator/coding-runtime)
plus the [GitHub Copilot CLI](https://github.com/github/copilot-cli) (`@github/copilot`).
The base owns the OS layer, the web terminal (xterm.js over a node-pty WebSocket
bridge, with a cross-origin guard and a 25s keepalive), `tini`, and the ETL that
turns the operator's `/etc/agent/config.yaml` into a normalized config. What lives
here is the three files that describe the Copilot CLI to it:

- **`runtime.json`** — the manifest: where config goes (`COPILOT_HOME=$STATE_DIR/copilot`),
  the serving surface, and how tmux launches the TUI.
- **`emit.mjs`** — the emitter: normalized config → Copilot CLI config under
  `$COPILOT_HOME`. Currently a placeholder that writes an empty `mcp-config.json`.
- **`launch-copilot-cli.sh`** — what tmux runs. The base has already set the working
  directory (the cloned repo when the agent sets `spec.repository`, else
  `/workspace`), so it opens that project directly.

One container, running the base entrypoint: resolve the environment, seed config,
serve. Seeding runs in the agent container rather than an init container because
the operator mounts `/tmp` there only, so the two would share no writable path.
tmux keeps the session alive across browser reconnects.

The sibling [`claude-code-adapter`](https://github.com/language-operator/claude-code-adapter)
is the same shape on the same base, swapping the CLI and the three files.

## Install

Prerequisite: the [`language-operator`](https://github.com/language-operator/language-operator)
chart must be installed first — it provides the `LanguageAgentRuntime` CRD.

```bash
helm install copilot-cli oci://ghcr.io/language-operator/charts/copilot-cli \
  --namespace language-operator
```

Then reference it from a `LanguageAgent`:

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: my-agent
spec:
  runtime: copilot-cli
```

No version is published yet; the first release is `v0.1.0`, cut by #1.

## Authentication

The runtime sets `auth.enabled: true`, so access is gated entirely by the cluster's
OIDC proxy: when the `LanguageCluster` has auth enabled the operator injects an
oauth2-proxy sidecar in front of the terminal. There is no built-in password — if
the cluster does not enable auth, the terminal is exposed unauthenticated on its
ingress. The Copilot CLI is to reach the model gateway as a BYOK provider, which
needs no GitHub sign-in; that wiring lands in #1.

## Licensing

The image redistributes the GitHub Copilot CLI unmodified, under the
[GitHub Copilot CLI License](https://github.com/github/copilot-cli/blob/main/LICENSE.md).
A copy ships in the image at `/usr/share/doc/github-copilot-cli/LICENSE.md`; see
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Development

```bash
make build      # docker build -t ghcr.io/language-operator/copilot-cli-adapter:latest .
make test       # build, then run the coding-runtime conformance suite
make publish    # build and push the image to ghcr.io
make dev        # build, import into k3s, and upgrade the runtime release (inner loop)

helm lint chart
helm template copilot-cli chart
```
