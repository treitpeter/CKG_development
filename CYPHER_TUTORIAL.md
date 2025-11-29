# Cypher Query Mini-Tutorial for CKG

This guide explains how to query the Clinical Knowledge Graph (CKG) using Neo4j's query language, Cypher.

## 1. The Basic Pattern: `MATCH` and `RETURN`

Cypher is like ASCII art. You draw the pattern you want to find.

*   **Nodes** are in parentheses: `(p:Protein)`
*   **Relationships** are in brackets: `-[r:INTERACTS_WITH]-`
*   **Properties** are in curly braces: `{name: "ALB"}`

**Example:** Find a protein named "ALB"
```cypher
MATCH (p:Protein {name: "ALB"})
RETURN p
```

## 2. Following Connections

You connect nodes with arrows `-->` to traverse the graph.

**Example:** Find what diseases "ALB" is associated with.
```cypher
MATCH (p:Protein {name: "ALB"})-[r:ASSOCIATED_WITH]->(d:Disease)
RETURN p, r, d
```

## 3. Querying Your Experiment

CKG connects your data in this hierarchy:
`Project` -> `Subject` -> `Biological_sample` -> `Analytical_sample` -> `Protein`

**Example:** Get all proteins in your "DIA-NN Proteomics Demo" project.
```cypher
MATCH (proj:Project {name: "DIA-NN Proteomics Demo"})
MATCH (proj)-[:HAS_ENROLLED]->(subj:Subject)
MATCH (subj)<-[:BELONGS_TO_SUBJECT]-(bio:Biological_sample)
MATCH (bio)-[:SPLITTED_INTO]->(ana:Analytical_sample)
MATCH (ana)-[:HAS_QUANTIFIED_PROTEIN]->(prot:Protein)
RETURN count(distinct prot)
```

## 4. Filtering and Limits

*   `WHERE`: Filter results (e.g., score > 0.9)
*   `LIMIT`: Limit the number of results (crucial for visualization)

**Example:** High-confidence interactions only.
```cypher
MATCH (p1:Protein)-[r:COMPILED_INTERACTS_WITH]->(p2:Protein)
WHERE r.score > 0.95
RETURN p1, r, p2
LIMIT 50
```

## 5. Tips for Visualization

To get a graph view in Neo4j Browser (instead of a table), make sure you `RETURN` both the **nodes** and the **relationships**.

*   **Good (Graph):** `RETURN p1, r, p2`
*   **Bad (Table):** `RETURN p1.name, p2.name`

## Common Relationship Types

*   **Proteins:** `:COMPILED_INTERACTS_WITH`, `:CURATED_INTERACTS_WITH`
*   **Diseases:** `:ASSOCIATED_WITH`, `:HAS_DISEASE`
*   **Pathways:** `:ANNOTATED_IN_PATHWAY`
*   **Experimental:** `:HAS_QUANTIFIED_PROTEIN`
