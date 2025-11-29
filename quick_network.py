#!/usr/bin/env python3
"""
Quick Network Visualization from CKG Neo4j Database
Run with: python3 quick_network.py
"""
import warnings
warnings.filterwarnings('ignore')

print("CKG Network Visualization")
print("=" * 50)

# Connect to Neo4j
from ckg.graphdb_connector import connector

print("\n1. Connecting to Neo4j...")
driver = connector.getGraphDatabaseConnectionConfiguration()
if not driver:
    print("ERROR: Could not connect to Neo4j")
    exit(1)
print("   Connected!")

# Query for protein-peptide network
print("\n2. Querying protein-peptide relationships...")
query = """
MATCH (p:Peptide)-[r:BELONGS_TO_PROTEIN]->(prot:Protein)
RETURN prot.name as protein, count(p) as peptide_count
ORDER BY peptide_count DESC
LIMIT 20
"""
result = connector.sendQuery(driver, query)
proteins_with_peptides = list(result)

print(f"\n   Top 20 proteins by peptide count:")
for row in proteins_with_peptides:
    print(f"   {row['protein']}: {row['peptide_count']} peptides")

# Query for gene-protein relationships
print("\n3. Querying gene-protein relationships...")
query2 = """
MATCH (g:Gene)
RETURN g.name as gene, g.family as family
LIMIT 20
"""
result2 = connector.sendQuery(driver, query2)
genes = list(result2)

print(f"\n   Sample genes in database:")
for row in genes[:10]:
    print(f"   {row['gene']} ({row['family']})")

# Create simple network visualization
print("\n4. Creating network visualization...")
try:
    import networkx as nx
    import matplotlib
    matplotlib.use('Agg')  # Non-interactive backend
    import matplotlib.pyplot as plt

    # Build a small network
    G = nx.Graph()

    # Add protein nodes and peptide counts as edges to a central "Proteome" node
    for row in proteins_with_peptides[:15]:
        G.add_node(row['protein'], node_type='protein')
        G.add_edge('Proteome', row['protein'], weight=row['peptide_count'])

    G.add_node('Proteome', node_type='center')

    # Draw network
    plt.figure(figsize=(14, 10))
    pos = nx.spring_layout(G, k=2, iterations=50)

    # Node colors
    node_colors = ['red' if G.nodes[n].get('node_type') == 'center' else 'lightblue'
                   for n in G.nodes()]

    nx.draw(G, pos,
            node_color=node_colors,
            node_size=1500,
            font_size=8,
            with_labels=True,
            edge_color='gray',
            alpha=0.8)

    plt.title("CKG: Top 15 Proteins by Peptide Count", fontsize=14)
    plt.savefig('/fs/pool/pool-mann-projects/Peter/CKG/network_proteins.png',
                dpi=150, bbox_inches='tight')
    print("   Saved: network_proteins.png")

except ImportError as e:
    print(f"   Visualization skipped (missing: {e})")

# Summary stats
print("\n5. Database Statistics:")
stats_query = "MATCH (n) RETURN labels(n)[0] as label, count(*) as count ORDER BY count DESC"
stats = connector.sendQuery(driver, stats_query)
total = 0
for row in stats:
    print(f"   {row['label']}: {row['count']:,}")
    total += row['count']
print(f"\n   Total nodes: {total:,}")

print("\n" + "=" * 50)
print("Done! Check network_proteins.png")
print("\nFor interactive exploration, use Neo4j Browser:")
print("  http://hpcl9301.biochem.mpg.de:7474")
print("  Username: neo4j")
print("  Password: ckg_password")
