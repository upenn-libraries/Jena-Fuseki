# SDBM Jena Fuseki

A customized [Apache Jena Fuseki](https://jena.apache.org/documentation/fuseki2/) Docker image for the [Schoenberg Database of Manuscripts (SDBM)](https://sdbm.library.upenn.edu/), providing a SPARQL 1.1 endpoint over the SDBM linked data.

Based on [stain/jena-fuseki](https://github.com/stain/jena-docker/tree/master/jena-fuseki).

## What It Is

The SDBM tracks the history of pre-modern manuscripts through auction records, dealer catalogs, and other sources, exposing that provenance data as RDF. This image runs Fuseki pre-configured with an `sdbm` TDB dataset, a custom SPARQL query interface, and a security policy that makes queries publicly accessible while restricting administrative operations.

## Customizations

| What | How |
|------|-----|
| Base image | `ubuntu:24.04` (replaces Alpine) |
| Fuseki version | 3.14.0 |
| Dataset | Pre-configured `sdbm` TDB1 dataset (`sdbm.ttl`) at `/fuseki/databases/sdbm` |
| Authentication | `ADMIN_PASSWORD` is **required** at startup; the container exits if it is missing |
| `shiro.ini` | Always overwritten at startup from the image copy, with `${ADMIN_PASSWORD}` substituted — redeployment reliably picks up a new password |
| Access control | SPARQL query endpoints and the UI are public (`anon`); all other operations require `admin` credentials |
| Query UI | Custom `qonsole-config.js` and `dataset.html` configure the SPARQL query interface for SDBM |

## Requirements

- Docker
- `ADMIN_PASSWORD` environment variable (required — container will not start without it)

## Running

### Quick start (foreground)

```bash
docker run -p 3030:3030 -e ADMIN_PASSWORD=changeme sdbm/jena-fuseki
```

Fuseki will be available at <http://localhost:3030/>. The `sdbm` dataset is at <http://localhost:3030/sdbm>.

### Local development

Copy `jena.env.example` to `jena.env` and edit as needed:

```bash
cp jena.env.example jena.env
# edit jena.env — do not commit this file
```

Then run with `--env-file`:

```bash
docker run -p 3030:3030 --env-file jena.env sdbm/jena-fuseki
```

### Environment variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ADMIN_PASSWORD` | **Yes** | — | Password for the `admin` user |
| `JVM_ARGS` | No | `-Xmx1200m` | JVM heap settings, e.g. `-Xmx3g` for large uploads |
| `VIRTUAL_HOST` | No | — | Hostname for a reverse proxy (e.g. `jena.example.com`) |
| `TDB` | No | `1` | Set to `2` to use TDB v2 |

## Data Persistence

Fuseki data lives in the Docker volume `/fuseki`. Without a named volume or bind mount, data is lost when the container is removed.

### Named volume (recommended)

```bash
docker volume create fuseki-data
docker run -d --name fuseki -p 3030:3030 -e ADMIN_PASSWORD=changeme -v fuseki-data:/fuseki sdbm/jena-fuseki
```

### Bind mount

```bash
docker run -d --name fuseki -p 3030:3030 -e ADMIN_PASSWORD=changeme -v /path/to/data:/fuseki sdbm/jena-fuseki
```

## Loading Data

For large datasets, load directly from the command line using the bundled `load.sh` script rather than the web UI. Stop Fuseki first, then load into the volume:

```bash
docker stop fuseki
docker run --rm -v fuseki-data:/fuseki -v /path/to/rdf/files:/staging sdbm/jena-fuseki ./load.sh sdbm /staging/sdbm.ttl
```

If no filenames are given, `load.sh` loads all matching files under `/staging` (`*.rdf`, `*.ttl`, `*.owl`, `*.nt`, `*.nquads`, and their `.gz` variants).

Restart Fuseki after loading:

```bash
docker restart fuseki
```

## Building

```bash
docker build -t sdbm/jena-fuseki .
```

## Common Operations

```bash
# View logs
docker logs fuseki

# Stop
docker stop fuseki

# Restart (retains volume and port config)
docker restart fuseki

# Upgrade: pull new image, recreate container against existing volume
docker pull sdbm/jena-fuseki
docker stop fuseki && docker rm fuseki
docker run -d --name fuseki -p 3030:3030 -e ADMIN_PASSWORD=changeme -v fuseki-data:/fuseki sdbm/jena-fuseki
```

## Access Control Summary

The `shiro.ini` configuration grants anonymous access to:
- The Fuseki web UI (`/`, `/index.html`, `/dataset.html`, static assets)
- SPARQL query endpoints (`/**/query`, `/$/sdbm`)
- Status and ping endpoints

All other endpoints — including dataset management, data upload, and graph store writes — require HTTP Basic authentication as `admin`.

## Upstream Resources

- [Apache Jena Fuseki documentation](https://jena.apache.org/documentation/fuseki2/)
- [stain/jena-docker source](https://github.com/stain/jena-docker)
- [Apache Jena TDB](https://jena.apache.org/documentation/tdb/)
- [Jena users mailing list](https://jena.apache.org/help_and_support/)

---

🤖 AI Usage Disclosure: README substantially rewritten by Claude (Anthropic) to document SDBM-specific customizations, required configuration, and operational usage.
