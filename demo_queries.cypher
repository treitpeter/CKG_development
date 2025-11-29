// =============================================================
// VISUAL NETWORK QUERIES (Run these to see Graphs!)
// =============================================================

// 1. Local Neighborhood of Top Protein (The "Hairball")
// Visualize the top abundant protein and its direct interaction partners.
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->(s:Subject)<-[:BELONGS_TO_SUBJECT]-(bs:Biological_sample)-[:SPLITTED_INTO]->(as:Analytical_sample)-[q:HAS_QUANTIFIED_PROTEIN]->(prot:Protein)
WITH prot, avg(q.value) as intensity ORDER BY intensity DESC LIMIT 1
MATCH (prot)-[r:COMPILED_INTERACTS_WITH]-(partner)
RETURN prot, r, partner LIMIT 50;

// 2. Biological Process & Pathway Clusters (The "Function")
// See how proteins cluster around shared GO terms and Pathways.
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->()<-[:BELONGS_TO_SUBJECT]-()-[:SPLITTED_INTO]->()-[:HAS_QUANTIFIED_PROTEIN]->(prot:Protein)
WITH collect(distinct prot) as proteins LIMIT 20
UNWIND proteins as p
MATCH (p)-[r1:ASSOCIATED_WITH]->(go:Biological_process)
MATCH (p)-[r2:ANNOTATED_IN_PATHWAY]->(pw:Pathway)
RETURN p, r1, go, r2, pw LIMIT 50;

// 3. Shortest Path Visualization (The "Bridge")
// See exactly how two proteins are connected.
MATCH (p1:Protein {name: "ALB"}), (p2:Protein {name: "HBB"}),
p = shortestPath((p1)-[:COMPILED_INTERACTS_WITH*..4]-(p2))
RETURN p;

// 4. Disease & Drug Connections (The "Clinical Context")
// Visualize proteins, their associated diseases, and potential drugs.
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->()<-[:BELONGS_TO_SUBJECT]-()-[:SPLITTED_INTO]->()-[:HAS_QUANTIFIED_PROTEIN]->(prot:Protein)
MATCH (prot)-[r1:ASSOCIATED_WITH]->(d:Disease)
OPTIONAL MATCH (d)-[r2:TARGETS]->(drug:Drug)
RETURN prot, r1, d, r2, drug LIMIT 50;

// 5. Protein Complex Visualization (The "Clique")
// See a dense cluster of interacting proteins.
MATCH (p:Protein)-[r:COMPILED_INTERACTS_WITH]-(neighbor)
WITH p, collect(neighbor) as neighbors, count(neighbor) as degree
WHERE degree > 10
MATCH (p)-[r]-(neighbor)
WHERE neighbor IN neighbors
RETURN p, r, neighbor LIMIT 50;

// 6. Project Data Structure (The "Schema")
// Visualize how your project connects to subjects and samples.
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[r1]->(s:Subject)<-[r2]-(bs:Biological_sample)-[r3]->(as:Analytical_sample)
RETURN p, r1, s, r2, bs, r3, as LIMIT 100;

// 7. Multi-Omics View (If available)
// Visualize connections between Proteins, Modified Proteins, and Transcripts
MATCH (p:Protein)-[r1:HAS_MODIFIED_SITE]->(mp:Modified_protein)
MATCH (p)<-[r2:TRANSLATED_INTO]-(t:Transcript)
RETURN p, r1, mp, r2, t LIMIT 30;

// 8. Shared Interaction Partners (The "Triangle")
// Visualize proteins that share a common neighbor.
MATCH (p1:Protein)-[r1:COMPILED_INTERACTS_WITH]->(common)<-[r2:COMPILED_INTERACTS_WITH]-(p2:Protein)
WHERE p1.name = "ALB"
RETURN p1, r1, common, r2, p2 LIMIT 20;

// 9. Variant & Chromosome Mapping
// See where your proteins map to the genome.
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->()<-[:BELONGS_TO_SUBJECT]-()-[:SPLITTED_INTO]->()-[:HAS_QUANTIFIED_PROTEIN]->(prot:Protein)
MATCH (prot)<-[r1:VARIANT_FOUND_IN_PROTEIN]-(v:Known_variant)-[r2:VARIANT_FOUND_IN_CHROMOSOME]->(c:Chromosome)
RETURN prot, r1, v, r2, c LIMIT 50;

// 10. The "Butterfly" (Hub and Spokes)
// Visualize a protein and its exclusive connections in this dataset.
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->()<-[:BELONGS_TO_SUBJECT]-()-[:SPLITTED_INTO]->()-[:HAS_QUANTIFIED_PROTEIN]->(prot:Protein)
WITH prot LIMIT 1
MATCH (prot)-[r]-(connected)
RETURN prot, r, connected;
