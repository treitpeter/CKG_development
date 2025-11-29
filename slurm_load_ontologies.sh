#!/bin/bash
#SBATCH --job-name=load_ontologies
#SBATCH --output=logs/load_ontologies_%j.out
#SBATCH --error=logs/load_ontologies_%j.err
#SBATCH --time=01:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4

cd /fs/pool/pool-mann-projects/Peter/CKG
source venv/bin/activate

echo "=== Loading Ontologies into Neo4j ==="
echo "Start time: $(date)"

python -c "
from ckg.graphdb_connector import connector
import os

driver = connector.getGraphDatabaseConnectionConfiguration()
import_dir = '/fs/pool/pool-mann-projects/Peter/CKG/data/imports/ontologies'

# Ontology files to load (columns: ID, :LABEL, name, description, type, synonyms)
ontology_files = ['Disease.tsv', 'Tissue.tsv', 'Phenotype.tsv', 'Biological_process.tsv', 'Modification.tsv']

with driver.session() as session:
    for filename in ontology_files:
        filepath = os.path.join(import_dir, filename)
        label = filename.replace('.tsv', '')

        if os.path.exists(filepath):
            print(f'Loading {label}...')

            # Create constraint first
            try:
                session.run(f'CREATE CONSTRAINT IF NOT EXISTS FOR (n:{label}) REQUIRE n.id IS UNIQUE')
            except Exception as e:
                print(f'  Constraint note: {e}')

            # Load data using the actual column names from the file
            query = f'''
            LOAD CSV WITH HEADERS FROM 'file:///{filepath}' AS row FIELDTERMINATOR '\\\t'
            MERGE (n:{label} {{id: row.ID}})
            SET n.name = row.name,
                n.description = row.description,
                n.synonyms = row.synonyms
            '''
            try:
                result = session.run(query)
                summary = result.consume()
                print(f'  {label}: Created {summary.counters.nodes_created} nodes, Set {summary.counters.properties_set} properties')
            except Exception as e:
                print(f'  Error loading {label}: {e}')
        else:
            print(f'  File not found: {filepath}')

driver.close()
print('Done!')
"

echo "End time: $(date)"
