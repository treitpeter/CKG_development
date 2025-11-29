// 1. Project Data Overview
MATCH (p:Project)-[:HAS_ENROLLED]->(s:Subject)<-[:BELONGS_TO_SUBJECT]-(bs:Biological_sample) RETURN p.name as Project, count(distinct s) as Subjects, count(distinct bs) as BiologicalSamples;

// 2. Top 10 Most Abundant Proteins
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->(s:Subject)<-[:BELONGS_TO_SUBJECT]-(bs:Biological_sample)-[:SPLITTED_INTO]->(as:Analytical_sample)-[q:HAS_QUANTIFIED_PROTEIN]->(prot:Protein) RETURN prot.name as Protein, avg(q.value) as AvgIntensity ORDER BY AvgIntensity DESC LIMIT 10;

// 3. Hub Proteins (Degree Centrality)
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->(s:Subject)<-[:BELONGS_TO_SUBJECT]-(bs:Biological_sample)-[:SPLITTED_INTO]->(as:Analytical_sample)-[:HAS_QUANTIFIED_PROTEIN]->(prot:Protein) WITH DISTINCT prot MATCH (prot)-[r:COMPILED_INTERACTS_WITH]-(other) RETURN prot.name as Protein, count(other) as Degree ORDER BY Degree DESC LIMIT 10;

// 4. Protein Communities (Shared Neighbors)
MATCH (p1:Protein)-[:COMPILED_INTERACTS_WITH]->(common)<-[:COMPILED_INTERACTS_WITH]-(p2:Protein) WHERE id(p1) < id(p2) WITH p1, p2, count(common) as CommonNeighbors WHERE CommonNeighbors > 5 RETURN p1.name, p2.name, CommonNeighbors ORDER BY CommonNeighbors DESC LIMIT 10;

// 5. Pathway Enrichment (Reactome)
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->(s:Subject)<-[:BELONGS_TO_SUBJECT]-(bs:Biological_sample)-[:SPLITTED_INTO]->(as:Analytical_sample)-[:HAS_QUANTIFIED_PROTEIN]->(prot:Protein) MATCH (prot)-[:ANNOTATED_IN_PATHWAY]->(pw:Pathway) RETURN pw.name as Pathway, count(distinct prot) as ProteinCount ORDER BY ProteinCount DESC LIMIT 15;

// 6. Disease Associations
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->(s:Subject)<-[:BELONGS_TO_SUBJECT]-(bs:Biological_sample)-[:SPLITTED_INTO]->(as:Analytical_sample)-[:HAS_QUANTIFIED_PROTEIN]->(prot:Protein) MATCH (prot)-[:ASSOCIATED_WITH]->(d:Disease) RETURN d.name as Disease, count(distinct prot) as ProteinCount ORDER BY ProteinCount DESC LIMIT 10;

// 7. Shortest Path between Two Proteins (Example: ALB and HBB)
MATCH (p1:Protein {name: "ALB"}), (p2:Protein {name: "HBB"}) MATCH path = shortestPath((p1)-[:COMPILED_INTERACTS_WITH*..4]-(p2)) RETURN path;

// 8. GO Biological Process Enrichment
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->(s:Subject)<-[:BELONGS_TO_SUBJECT]-(bs:Biological_sample)-[:SPLITTED_INTO]->(as:Analytical_sample)-[:HAS_QUANTIFIED_PROTEIN]->(prot:Protein) MATCH (prot)-[:ASSOCIATED_WITH]->(go:Biological_process) RETURN go.name as Process, count(distinct prot) as Count ORDER BY Count DESC LIMIT 15;

// 9. Bridge Proteins
MATCH (a:Protein)-[:COMPILED_INTERACTS_WITH]->(bridge:Protein)-[:COMPILED_INTERACTS_WITH]->(b:Protein) WHERE NOT (a)-[:COMPILED_INTERACTS_WITH]-(b) RETURN bridge.name as BridgeProtein, count(distinct a) as Connections ORDER BY Connections DESC LIMIT 10;

// 10. Experiment-Specific Subgraph
MATCH (p:Project {name: "DIA-NN Proteomics Demo"})-[:HAS_ENROLLED]->(s:Subject)<-[:BELONGS_TO_SUBJECT]-(bs:Biological_sample)-[:SPLITTED_INTO]->(as:Analytical_sample)-[:HAS_QUANTIFIED_PROTEIN]->(prot:Protein) WITH collect(distinct prot) as my_proteins MATCH (p1)-[r:COMPILED_INTERACTS_WITH]->(p2) WHERE p1 IN my_proteins AND p2 IN my_proteins RETURN p1, r, p2 LIMIT 50;
