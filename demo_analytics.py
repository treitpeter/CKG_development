#!/usr/bin/env python3
"""
CKG 2026 - Minimal Demo
Demonstrates analytics capabilities without Neo4j

Run with:
    source venv/bin/activate
    PYTHONPATH=. python3 demo_analytics.py
"""

import warnings
warnings.filterwarnings('ignore')

import numpy as np
import pandas as pd

print("CKG 2026 - Analytics Demo")
print("=" * 50)
print()

# Test imports
print("1. Testing core imports...")
from ckg.analytics_core.analytics import analytics
print("   analytics module: OK")

# Generate sample proteomics data
print()
print("2. Generating sample proteomics data...")
np.random.seed(42)
n_samples = 30
n_proteins = 100

# Create sample data (simulating proteomics intensity values)
data = pd.DataFrame(
    np.random.lognormal(mean=10, sigma=2, size=(n_samples, n_proteins)),
    columns=[f"Protein_{i}" for i in range(n_proteins)],
    index=[f"Sample_{i}" for i in range(n_samples)]
)

# Add group information
groups = ['Control'] * 15 + ['Treatment'] * 15
data['group'] = groups

print(f"   Created dataset: {n_samples} samples x {n_proteins} proteins")
print(f"   Groups: Control (15), Treatment (15)")

# Run basic statistics
print()
print("3. Running statistical analysis...")

# Prepare data for analysis
numeric_data = data.drop('group', axis=1)

# Calculate log2 fold changes
control_mean = numeric_data[data['group'] == 'Control'].mean()
treatment_mean = numeric_data[data['group'] == 'Treatment'].mean()
fold_changes = np.log2(treatment_mean / control_mean)

# Find top changed proteins
top_up = fold_changes.nlargest(5)
top_down = fold_changes.nsmallest(5)

print("   Top 5 upregulated proteins:")
for protein, fc in top_up.items():
    print(f"      {protein}: log2FC = {fc:.2f}")

print()
print("   Top 5 downregulated proteins:")
for protein, fc in top_down.items():
    print(f"      {protein}: log2FC = {fc:.2f}")

# PCA analysis
print()
print("4. Running PCA dimensionality reduction...")
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler

scaler = StandardScaler()
scaled_data = scaler.fit_transform(numeric_data)

pca = PCA(n_components=2)
pca_result = pca.fit_transform(scaled_data)

print(f"   Variance explained: PC1={pca.explained_variance_ratio_[0]*100:.1f}%, PC2={pca.explained_variance_ratio_[1]*100:.1f}%")

# UMAP analysis
print()
print("5. Running UMAP dimensionality reduction...")
try:
    import umap
    reducer = umap.UMAP(n_neighbors=10, min_dist=0.1, random_state=42)
    umap_result = reducer.fit_transform(scaled_data)
    print(f"   UMAP embedding created: {umap_result.shape}")
except Exception as e:
    print(f"   UMAP skipped: {e}")

# Network analysis
print()
print("6. Building protein correlation network...")
import networkx as nx

# Calculate correlations
corr_matrix = numeric_data.T.corr()

# Build network with high correlations
G = nx.Graph()
threshold = 0.7

for i, protein1 in enumerate(corr_matrix.columns[:20]):  # First 20 proteins
    for j, protein2 in enumerate(corr_matrix.columns[:20]):
        if i < j and abs(corr_matrix.iloc[i, j]) > threshold:
            G.add_edge(protein1, protein2, weight=corr_matrix.iloc[i, j])

print(f"   Network: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges")
print(f"   Density: {nx.density(G):.3f}")

# Clustering
print()
print("7. Running community detection...")
try:
    import community as community_louvain
    if G.number_of_nodes() > 0 and G.number_of_edges() > 0:
        partition = community_louvain.best_partition(G)
        n_communities = len(set(partition.values()))
        print(f"   Found {n_communities} communities using Louvain algorithm")
    else:
        print("   Network too sparse for clustering")
except Exception as e:
    print(f"   Clustering skipped: {e}")

print()
print("=" * 50)
print("Demo complete!")
print()
print("This demonstrates CKG's analytical capabilities.")
print("For full functionality, connect to Neo4j database.")
print("=" * 50)
