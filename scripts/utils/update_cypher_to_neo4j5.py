#!/usr/bin/env python3
"""Update cypher.yml from Neo4j 4.x to Neo4j 5.x syntax"""
import re

# Read the file
with open('/fs/pool/pool-mann-projects/Peter/CKG/ckg/graphdb_builder/builder/cypher.yml', 'r') as f:
    content = f.read()

# 1. Update CREATE CONSTRAINT syntax
# FROM: CREATE CONSTRAINT ON (e:ENTITY) ASSERT e.id IS UNIQUE;
# TO: CREATE CONSTRAINT IF NOT EXISTS FOR (e:ENTITY) REQUIRE e.id IS UNIQUE;
content = re.sub(
    r'CREATE CONSTRAINT ON \((\w+):(\w+)\) ASSERT (\w+)\.(\w+) IS UNIQUE',
    r'CREATE CONSTRAINT IF NOT EXISTS FOR (\1:\2) REQUIRE \3.\4 IS UNIQUE',
    content
)

# 2. Update CREATE INDEX syntax
# FROM: CREATE INDEX ON :Label(prop);
# TO: CREATE INDEX IF NOT EXISTS FOR (n:Label) ON (n.prop);
content = re.sub(
    r'CREATE INDEX ON :(\w+)\((\w+)\)',
    r'CREATE INDEX IF NOT EXISTS FOR (n:\1) ON (n.\2)',
    content
)

# 3. Remove USING PERIODIC COMMIT (Neo4j 5.x handles batching internally for LOAD CSV)
# The LOAD CSV in Neo4j 5 handles batching automatically now
content = re.sub(
    r'USING PERIODIC COMMIT \d+\s*\n\s*',
    '',
    content
)
# Also handle case without newline
content = re.sub(
    r'USING PERIODIC COMMIT \d+\s+',
    '',
    content
)

# Write the updated file
with open('/fs/pool/pool-mann-projects/Peter/CKG/ckg/graphdb_builder/builder/cypher.yml', 'w') as f:
    f.write(content)

print("Updated cypher.yml to Neo4j 5.x syntax:")
print(f"  - Updated CREATE CONSTRAINT syntax")
print(f"  - Updated CREATE INDEX syntax")
print(f"  - Removed USING PERIODIC COMMIT (Neo4j 5 handles batching internally)")
