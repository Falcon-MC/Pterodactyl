# Falcon - Pterodactyl egg

Runs [Falcon](https://github.com/Falcon-MC/Falcon), a Minecraft: Bedrock Edition server written in C++17 (protocol 2193, Minecraft 1.26.50), from the prebuilt Linux binary published on GitHub releases.

The egg declares an `update_url`, so the panel can pull new versions of it from this repository.

## Install

1. In the Pterodactyl panel, go to **Admin → Nests → Import Egg**.
2. Upload `egg-falcon.json` and pick the nest to import it into.
3. Create a server with that egg. Give it a **UDP** allocation - Bedrock does not use TCP.

The install script resolves the release through the GitHub API, downloads `FalconServer-linux-x64`, verifies it against the published SHA-256 and writes a default `server.properties` if none exists.

## Updating

`RELEASE_VERSION` defaults to `latest`, so **reinstalling the server pulls the newest release**. Set it to a version such as `1.0.0` to pin one instead; the leading `v` is added automatically.

Reinstalling only replaces the binary. `worlds/`, `server.properties`, `behavior_packs/` and `resource_packs/` are left alone.

## Docker image

Falcon links dynamically. The binary is built on Ubuntu 22.04 and needs:

| Dependency | Required |
| --- | --- |
| glibc | 2.35 or newer |
| libstdc++ | GLIBCXX 3.4.30 (GCC 12) |
| OpenSSL | `libssl.so.3`, `libcrypto.so.3` |
| zlib | `libz.so.1` |

Debian 12 and Ubuntu 22.04 satisfy all of these. **Debian 11 does not** - its glibc is 2.31, and the server will refuse to start. Only those two images are offered by the egg for that reason.

## Stopping

The stop command is `^C`, not `stop`. Falcon has no `stop` console command; it shuts down on `SIGINT`/`SIGTERM`, and that path is what saves modified chunks and player data. Killing the process instead loses everything since the last save.

Known issue: after `Saved N chunk(s)` the process may not exit on its own. The data is already saved at that point, so a second stop (or letting the panel kill it) is safe.

## Variables

| Variable | Default | Notes |
| --- | --- | --- |
| `RELEASE_VERSION` | `latest` | `latest`, or a pinned version like `1.0.0` |
| `REPOSITORY` | `Falcon-MC/Falcon` | Admin-only |
| `GITHUB_TOKEN` | empty | Admin-only, needed only if the node hits the anonymous API rate limit |
| `SERVER_NAME` | `Falcon Server` | Shown in the server list |
| `LEVEL_NAME` | `Bedrock level` | Folder under `worlds/` |
| `LEVEL_SEED` | empty | Random when empty |
| `GAMEMODE` | `survival` | `survival`, `creative`, `adventure` |
| `DIFFICULTY` | `easy` | `peaceful`, `easy`, `normal`, `hard` |
| `MAX_PLAYERS` | `20` | |
| `ONLINE_MODE` | `true` | Requires Xbox Live authentication |
| `ALLOW_CHEATS` | `true` | |
| `VIEW_DISTANCE` | `10` | Chunks streamed per player |
| `TICK_DISTANCE` | `4` | Chunks kept ticking per player |
| `ALLOW_LIST` | `false` | Only players in `allowlist.json` can join |
| `SPAWN_PROTECTION` | `16` | Radius where only operators can build; `-1` disables it |
| `SKIN_CHANGE_COOLDOWN` | `30` | Seconds between two skin changes of a player |
| `SERVER_PORT_V6` | `19133` | Give it its own allocation for IPv6 clients |

`server-port` follows the primary allocation. `enable-lan-visibility` is forced to `false`, since LAN discovery is meaningless inside a container.

## Known limitations

- Falcon is an in-progress reimplementation, not a drop-in replacement for the official Bedrock Dedicated Server. Expect missing gameplay.
- The Linux binary is built and linked by CI on every release, but is not run there. Compiling is not the same as working.
