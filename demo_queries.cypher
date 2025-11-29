// =============================================================
// DEMO NETWORK QUERIES (Tested & Visual)
// =============================================================

// 1. Local Neighborhood (The "Hairball")
// Visualize the top abundant protein and its direct interaction partners.
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->(s:Subject)<-[:BELONGS_TO_SUBJECT]-(bs:Biological_sample)-[:SPLITTED_INTO]->(as:Analytical_sample)-[q:HAS_QUANTIFIED_PROTEIN]->(prot:Protein)
WITH prot, avg(q.value) as intensity ORDER BY intensity DESC LIMIT 1
MATCH (prot)-[r:COMPILED_INTERACTS_WITH]-(partner)
RETURN prot, r, partner LIMIT 50;

// 2. Shortest Path (The "Bridge")
// See exactly how two proteins are connected.
MATCH (p1:Protein {name: "ALB"}), (p2:Protein {name: "HBB"}),
p = shortestPath((p1)-[:COMPILED_INTERACTS_WITH*..4]-(p2))
RETURN p;

// 3. Protein Complex (The "Clique")
// See a dense cluster of interacting proteins.
MATCH (p:Protein)-[r:COMPILED_INTERACTS_WITH]-(neighbor)
WITH p, collect(neighbor) as neighbors, count(neighbor) as degree
WHERE degree > 10
MATCH (p)-[r]-(neighbor)
WHERE neighbor IN neighbors
RETURN p, r, neighbor LIMIT 50;

// 4. Project Data Structure (The "Schema")
// Visualize how your project connects to subjects and samples.
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[r1]->(s:Subject)<-[r2]-(bs:Biological_sample)-[r3]->(as:Analytical_sample)
RETURN p, r1, s, r2, bs, r3, as LIMIT 100;

// 5. Shared Interaction Partners (The "Triangle")
// Visualize proteins that share a common neighbor.
MATCH (p1:Protein)-[r1:COMPILED_INTERACTS_WITH]->(common)<-[r2:COMPILED_INTERACTS_WITH]-(p2:Protein)
WHERE p1.name = "ALB"
RETURN p1, r1, common, r2, p2 LIMIT 20;

// 6. Simple Disease Association
// See proteins linked to a specific disease.
MATCH (p:Protein)-[r:ASSOCIATED_WITH]->(d:Disease {name: "Alzheimer's disease"})
RETURN p, r, d LIMIT 50;
