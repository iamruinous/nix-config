# Monolith Caddy Routes

Hostname catalog for `Caddyfile.age` - enables searching without decryption.

**Host:** monolith (primary services server)

## Domain Mappings

| Domain | Service | Description |
|--------|---------|-------------|
| `adminer.meskill.farm` | adminer | Database admin UI |
| `apprise.meskill.farm` | apprise | Notification service |
| `autobrr.meskill.farm` | autobrr | Torrent automation |
| `bazarr.meskill.farm` | bazarr | Subtitle management |
| `books.meskill.farm` | kavita | Kavita book server |
| `ca.meskill.farm` | stepca | Step CA certificate authority |
| `calibre-dt.meskill.farm` | calibre | Calibre desktop |
| `calibre.meskill.farm` | calibre-automated | Calibre automated |
| `calibre-dl.meskill.farm` | gluetun:8085 | Calibre download (via VPN) |
| `changes.meskill.farm` | changedetection | Change detection service |
| `deluge.meskill.farm` | gluetun:8112 | Deluge torrent (via VPN) |
| `etv.meskill.farm` | ersatztv | ErsatzTV IPTV server |
| `frigate.meskill.farm` | frigate | Frigate NVR |
| `forge.meskill.farm` | forgejo | Forgejo git server |
| `glance.meskill.farm` | glance | Glance dashboard |
| `grafana.meskill.farm` | grafana | Grafana monitoring |
| `gotenberg.meskill.farm` | gotenberg | PDF generation service |
| `kavita.meskill.farm` | kavita | Kavita book server |
| `ldap.meskill.farm` | phpldapadmin | LDAP admin UI |
| `loki.meskill.farm` | loki | Loki log aggregation |
| `mqtt-explorer.meskill.farm` | mqtt-explorer | MQTT Explorer |
| `mqtt.meskill.farm` | mosquitto | MQTT broker (websocket) |
| `nocodb.meskill.farm` | nocodb | NocoDB database UI |
| `n8n.meskill.farm` | n8n | n8n workflow automation |
| `n8h.meskill.farm` | n8n | n8n webhooks only (restricted) |
| `pinchflat.meskill.farm` | pinchflat | Pinchflat media downloader |
| `paperless.meskill.farm` | paperless-ngx | Paperless-ngx documents |
| `paperless-ai.meskill.farm` | paperless-ai | Paperless AI assistant |
| `prometheus.meskill.farm` | prometheus | Prometheus metrics |
| `prowlarr.meskill.farm` | prowlarr | Prowlarr indexer manager |
| `radarr.meskill.farm` | radarr | Radarr movie manager |
| `readarr.meskill.farm` | readarr | Readarr book manager |
| `romm.meskill.farm` | romm | ROM manager |
| `rtl433.meskill.farm` | 10.55.20.24:8433 | RTL-SDR 433MHz receiver |
| `rtl915.meskill.farm` | 10.55.20.24:8915 | RTL-SDR 915MHz receiver |
| `sabnzbd.meskill.farm` | gluetun:8080 | SABnzbd (via VPN) |
| `seerr.meskill.farm` | jellyseerr | Jellyseerr media requests |
| `sonarr.meskill.farm` | sonarr | Sonarr TV manager |
| `tasks.meskill.farm` | tasktrove | TaskTrove task manager |
| `uptime.meskill.farm` | gatus | Gatus uptime monitoring |
| `zigbee.meskill.farm` | zigbee2mqtt | Zigbee2MQTT |

## Notes

- VPN-tunneled services route through `gluetun` container
- `n8h.meskill.farm` restricts access to webhooks and MCP endpoints only
- RTL-SDR endpoints point to external IP (Pi cluster node)
