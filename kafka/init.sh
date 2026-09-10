#!/bin/bash
set -euo pipefail

IFS=',' read -ra topics <<< "$KAFKA_AUDIT_TOPICS"
for topic in "${topics[@]}"; do
    /opt/kafka/bin/kafka-topics.sh \
        --bootstrap-server kafka:9092 \
        --create \
        --if-not-exists \
        --topic "$topic" \
        --partitions "$KAFKA_NUM_PARTITIONS" \
        --replication-factor 1
done
