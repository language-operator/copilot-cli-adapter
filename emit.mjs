/**
 * GitHub Copilot CLI emitter.
 *
 * Placeholder until #1, which translates the normalized config: the gateway as
 * a BYOK provider, LanguageTools as MCP servers, instructions as AGENTS.md.
 * For now it writes an empty MCP config into $COPILOT_HOME, so seeding has a
 * file to own and the runtime contract holds.
 */
export function emit(config) {
  const configDir = config.paths.stateDir ? `${config.paths.stateDir}/copilot` : '/etc/copilot';

  // Every owned key is supplied on every run, so a server dropped from the
  // config disappears from the file on the next seed.
  return [{ path: `${configDir}/mcp-config.json`, values: { mcpServers: {} }, owns: ['mcpServers'] }];
}

export default emit;
