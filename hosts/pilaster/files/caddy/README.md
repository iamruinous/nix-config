# Pilaster Caddy Routes

Hostname catalog for `Caddyfile.age` - enables searching without decryption.

**Host:** pilaster (secondary services server)

## Domain Mappings

| Domain | Service | Description |
|--------|---------|-------------|
| `auth.meskill.farm` | authentik | Authentik identity provider |
| `archive.meskill.farm` | archivebox | ArchiveBox web archiver |
| `homebox.meskill.farm` | homebox | Homebox inventory |
| `poll-int.meskill.family` | rallly | Rallly polls (internal) |
| `poll.meskill.family` | rallly | Rallly polls (external) |
| `azimutt.meskill.farm` | azimutt | Azimutt database explorer |
| `docs.meskill.farm` | wikijs | Wiki.js documentation |
| `wiki.meskill.farm` | wikijs | Wiki.js documentation (alt) |
| `ma-int.meskill.farm` | 172.17.0.1:8095 | Music Assistant (internal) |
| `ma.meskill.farm` | 172.17.0.1:8097 | Music Assistant (external) |
| `ma-alexa-int.meskill.farm` | music-assistant-alexa | Music Assistant Alexa (internal) |
| `ma-alexa.meskill.farm` | music-assistant-alexa | Music Assistant Alexa (external) |
| `mcp.meskill.farm` | mcp-gateway | Model Context Protocol gateway |
| `nutify-netrack.meskill.farm` | nutify-netrack | Nutify UPS monitor (Netrack) |
| `nutify-servers.meskill.farm` | nutify-servers | Nutify UPS monitor (Servers) |
| `qdrant.meskill.farm` | qdrant | Qdrant vector database |
| `monica-int.meskill.farm` | monica | Monica CRM (internal) |
| `monica.meskill.farm` | monica | Monica CRM (external) |
| `twenty-int.meskill.farm` | twenty | Twenty CRM (internal) |
| `twenty.meskill.farm` | twenty | Twenty CRM (external) |
| `netboot.meskill.farm` | netbootxyz | Netboot.xyz PXE server |
| `files.meskill.farm` | filestash | Filestash file manager |
| `homarr.meskill.farm` | homarr | Homarr dashboard |

### ruinous.social Services (Migrated)

| Domain | Service | Description |
|--------|---------|-------------|
| `alby-int.ruinous.social` | albyhub | Alby Hub Bitcoin wallet (internal) |
| `alby.ruinous.social` | albyhub | Alby Hub Bitcoin wallet (external) |
| `dav-int.ruinous.social` | baikal | Baikal CalDAV/CardDAV (internal) |
| `dav.ruinous.social` | baikal | Baikal CalDAV/CardDAV (external) |
| `meals-int.ruinous.social` | mealie | Mealie recipes (internal) |
| `meals.ruinous.social` | mealie | Mealie recipes (external) |
| `blog-int.ruinous.social` | writefreely | WriteFreely blog (internal) |
| `blog.ruinous.social` | writefreely | WriteFreely blog (external) |
| `keep-int.ruinous.social` | karakeep | Karakeep bookmarks (internal) |
| `keep.ruinous.social` | karakeep | Karakeep bookmarks (external) |
| `hoarder.ruinous.social` | karakeep | Karakeep bookmarks (legacy) |
| `karakeep.ruinous.social` | karakeep | Karakeep bookmarks (alt) |
| `links-int.ruinous.social` | linkstack | LinkStack links (internal) |
| `links.ruinous.social` | linkstack | LinkStack links (external) |
| `matrix-int.ruinous.social` | synapse + maubot | Matrix homeserver (internal) |
| `matrix.ruinous.social` | synapse + maubot | Matrix homeserver (external) |
| `ruinous-int.ruinous.social` | mastodon-web | Mastodon + Matrix (internal) |
| `ruinous.social` | mastodon-web | Mastodon + Matrix (external) |

## Notes

- Internal suffix `-int` indicates internal-only access
- Music Assistant uses host networking (172.17.0.1)
- ruinous.social services migrated from tty-ruinous-social
- Matrix routes split between synapse and maubot based on path
- Mastodon streaming served separately at `/api/v1/streaming/*`
