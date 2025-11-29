// =============================================================
// VISUAL NETWORK QUERIES (Run these to see Graphs!)
// =============================================================

// 1. Local Neighborhood of Top Protein (The "Hairball")
// Visualize the top abundant protein and its direct interaction partners.
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->(s:Subject)<-[:BELONGS_TO_SUBJECT]-(bs:Biological_sample)-[:SPLITTED_INTO]->(as:Analytical_sample)-[q:HAS_QUANTIFIED_PROTEIN]->(prot:Protein)
WITH prot, avg(q.value) as intensity ORDER BY intensity DESC LIMIT 1
MATCH (prot)-[r:COMPILED_INTERACTS_WITH]-(partner)
RETURN prot, r, partner LIMIT 50;

// 2. Shortest Path Visualization (The "Bridge")
// See exactly how two proteins are connected.
MATCH (p1:Protein {name: "ALB"}), (p2:Protein {name: "HBB"}),
p = shortestPath((p1)-[:COMPILED_INTERACTS_WITH*..4]-(p2))
RETURN p;

// 3. Protein Complex Visualization (The "Clique")
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

// 5. Common Function Cluster (The "Module")
// Visualize proteins that all participate in the same biological process.
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->()<-[:BELONGS_TO_SUBJECT]-()-[:SPLITTED_INTO]->()-[:HAS_QUANTIFIED_PROTEIN]->(prot:Protein)
MATCH (prot)-[r:ASSOCIATED_WITH]->(go:Biological_process)
WITH go, collect(prot) as proteins, count(prot) as count
ORDER BY count DESC LIMIT 1
MATCH (go)<-[r2]-(p)
WHERE p IN proteins
RETURN go, r2, p;

// 6. Shared Interaction Partners (The "Triangle")
// Visualize proteins that share a common neighbor.
MATCH (p1:Protein)-[r1:COMPILED_INTERACTS_WITH]->(common)<-[r2:COMPILED_INTERACTS_WITH]-(p2:Protein)
WHERE p1.name = "ALB"
RETURN p1, r1, common, r2, p2 LIMIT 20;

// 7. Experiment vs. Knowledge (The "Context")
// Visualize which of your experimental proteins interact with a specific known protein (e.g. TP53).
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->()<-[:BELONGS_TO_SUBJECT]-()-[:SPLITTED_INTO]->()-[:HAS_QUANTIFIED_PROTEIN]->(my_prot:Protein)
MATCH (my_prot)-[r:COMPILED_INTERACTS_WITH]-(target:Protein {name: "TP53"})
RETURN my_prot, r, target;

// 8. Disease Subgraph (The "Disease Network")
// Visualize proteins in your data linked to a specific disease.
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->()<-[:BELONGS_TO_SUBJECT]-()-[:SPLITTED_INTO]->()-[:HAS_QUANTIFIED_PROTEIN]->(prot:Protein)
MATCH (prot)-[r:ASSOCIATED_WITH]->(d:Disease {name: "Alzheimer's disease"})
RETURN prot, r, d;

// 9. Strongest Interactions Only (The "Skeleton")
// Visualize only the highest confidence interactions (>0.9).
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->()<-[:BELONGS_TO_SUBJECT]-()-[:SPLITTED_INTO]->()-[:HAS_QUANTIFIED_PROTEIN]->(prot:Protein)
MATCH (prot)-[r:COMPILED_INTERACTS_WITH]-(partner)
WHERE r.score > 0.9
RETURN prot, r, partner LIMIT 50;

// 10. The "Butterfly" (Hub and Spokes)
// Visualize a protein and its exclusive connections in this dataset.
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->()<-[:BELONGS_TO_SUBJECT]-()-[:SPLITTED_INTO]->()-[:HAS_QUANTIFIED_PROTEIN]->(prot:Protein)
WITH prot LIMIT 1
MATCH (prot)-[r]-(connected)
RETURN prot, r, connected;
