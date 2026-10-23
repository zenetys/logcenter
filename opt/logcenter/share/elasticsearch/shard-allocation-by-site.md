# Distributing shards across sites

## Overview

Elasticsearch's
[shard allocation awareness](https://www.elastic.co/docs/deploy-manage/distributed-architecture/shard-allocation-relocation-recovery/shard-allocation-awareness)
keeps a primary shard and its replica on nodes that differ on a chosen
attribute. Here the attribute is `site`, the physical location of each node, so
losing one site never loses both copies of a shard.

This mechanism can be set up with the following procedure.

## Tag each data node with its site

On **every data node**, edit `/etc/elasticsearch/elasticsearch.yml` and set a
custom node attribute. The attribute name is up to you; we use `site`. Nodes in
the same location share the same value, and each location gets its own value.

```yaml
# Site, zone, room, hypervisor, etc.
node.attr.site: pve1
```

An environment variable (e.g. `node.attr.site: ${ES_SITE}`) would let you keep
one shared config file, but it is not the easiest to work with. The variable
must be defined, otherwise the Elasticsearch server and command-line tools will
not start; also, the `${VAR:default}` syntax does not work, contrary to what the
documentation says.

## Stop zsync'ing Elasticsearch configuration file

Add the file to the zsync `EXCLUDES` array, or more simply copy the provided
sample include file into `/etc/logcenter` on cluster nodes:

```bash
cp /opt/logcenter/share/zsync/zsync-per-node-es-site.inc.conf /etc/logcenter/
zsync -f
```

## Restart the nodes

The attribute is only read at startup, so each data node must be restarted. To
avoid needless shard movement during each restart, you can follow the standard
rolling-restart pattern:

```bash
es-maintenance begin-rolling

    # repeat on each node
    es-maintenance begin-node &&
        systemctl restart elasticsearch &&
        es-maintenance wait-node &&
        es-maintenance end-node &&
        es-maintenance wait-green &&
        echo "OK, proceed with next node"

es-maintenance end-rolling
```

## Enable allocation awareness

Enable awareness on the cluster. Elasticsearch then relocates shards so that a
primary and its replica never sit on nodes with the same `site` value.

```bash
es-curl _cluster/settings -X PUT \
    -d '{"persistent":{"cluster.routing.allocation.awareness.attributes":"site"}}'
```

## Enable forced awareness (optional, recommended)

Without forced awareness, if one site goes down Elasticsearch rebuilds all
missing replicas on the surviving site, which can overload it (disk, I/O,
network). Forced awareness prevents this; all expected values of the attribute
must be listed:

```bash
es-curl _cluster/settings -X PUT \
    -d '{"persistent":{"cluster.routing.allocation.awareness.force.site.values":"default,pve1,pve2"}}'
```
