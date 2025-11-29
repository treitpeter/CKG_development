#!/usr/bin/env python3
"""
CKG_PeTr - Comprehensive Test Suite
Run with: PYTHONPATH=. python3 test_ckg.py
"""

import warnings
warnings.filterwarnings('ignore')

import sys
import importlib
import traceback

# Colors for terminal
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def test_module(module_name):
    """Test if a module can be imported"""
    try:
        importlib.import_module(module_name)
        return True, None
    except Exception as e:
        return False, str(e)[:100]

def run_tests():
    print(f"\n{Colors.BOLD}{'='*70}")
    print("CKG_PeTr - Comprehensive Test Suite")
    print(f"{'='*70}{Colors.ENDC}\n")

    results = {
        'passed': 0,
        'failed': 0,
        'warnings': 0,
        'failed_modules': []
    }

    # Test categories
    test_categories = {
        'Core Modules': [
            'ckg.ckg_utils',
            'ckg.init',
        ],
        'Graph Connector': [
            'ckg.graphdb_connector.connector',
        ],
        'Graph Builder - Core': [
            'ckg.graphdb_builder.builder_utils',
            'ckg.graphdb_builder.mapping',
            'ckg.graphdb_builder.builder.builder',
            'ckg.graphdb_builder.builder.create_user',
            'ckg.graphdb_builder.builder.importer',
        ],
        'Graph Builder - Controllers': [
            'ckg.graphdb_builder.experiments.experiments_controller',
            'ckg.graphdb_builder.ontologies.ontologies_controller',
            'ckg.graphdb_builder.users.users_controller',
        ],
        'Database Parsers': [
            'ckg.graphdb_builder.databases.parsers.uniprotParser',
            'ckg.graphdb_builder.databases.parsers.drugBankParser',
            'ckg.graphdb_builder.databases.parsers.disgenetParser',
            'ckg.graphdb_builder.databases.parsers.stringParser',
            'ckg.graphdb_builder.databases.parsers.reactomeParser',
            'ckg.graphdb_builder.databases.parsers.hmdbParser',
            'ckg.graphdb_builder.databases.parsers.hgncParser',
            'ckg.graphdb_builder.databases.parsers.corumParser',
            'ckg.graphdb_builder.databases.parsers.intactParser',
            'ckg.graphdb_builder.databases.parsers.pfamParser',
            'ckg.graphdb_builder.databases.parsers.siderParser',
            'ckg.graphdb_builder.databases.parsers.signorParser',
            'ckg.graphdb_builder.databases.parsers.goaParser',
            'ckg.graphdb_builder.databases.parsers.hpaParser',
            'ckg.graphdb_builder.databases.parsers.refseqParser',
            'ckg.graphdb_builder.databases.parsers.oncokbParser',
            'ckg.graphdb_builder.databases.parsers.foodbParser',
            'ckg.graphdb_builder.databases.parsers.exposomeParser',
            'ckg.graphdb_builder.databases.parsers.smpdbParser',
            'ckg.graphdb_builder.databases.parsers.pspParser',
            'ckg.graphdb_builder.databases.parsers.textminingParser',
            'ckg.graphdb_builder.databases.parsers.pathwayCommonsParser',
            'ckg.graphdb_builder.databases.parsers.gwasCatalogParser',
            'ckg.graphdb_builder.databases.parsers.drugGeneInteractionDBParser',
            'ckg.graphdb_builder.databases.parsers.cancerGenomeInterpreterParser',
            'ckg.graphdb_builder.databases.parsers.mutationDsParser',
            'ckg.graphdb_builder.databases.parsers.jensenlabParser',
        ],
        'Analytics Core': [
            'ckg.analytics_core.analytics.analytics',
            'ckg.analytics_core.utils',
            'ckg.analytics_core.viz.viz',
        ],
        'Report Manager - Core': [
            'ckg.report_manager.report',
            'ckg.report_manager.utils',
            'ckg.report_manager.knowledge',
            'ckg.report_manager.project',
            'ckg.report_manager.user',
        ],
        'Report Manager - Apps': [
            'ckg.report_manager.apps.basicApp',
            'ckg.report_manager.apps.loginApp',
            'ckg.report_manager.apps.adminApp',
            'ckg.report_manager.apps.dataUploadApp',
            'ckg.report_manager.apps.projectApp',
            'ckg.report_manager.apps.projectCreationApp',
            'ckg.report_manager.apps.homepageStats',
            'ckg.report_manager.apps.initialApp',
            'ckg.report_manager.apps.imports',
        ],
    }

    for category, modules in test_categories.items():
        print(f"{Colors.BLUE}{Colors.BOLD}{category}{Colors.ENDC}")

        for module in modules:
            success, error = test_module(module)
            short_name = module.split('.')[-1]

            if success:
                print(f"  {Colors.GREEN}[OK]{Colors.ENDC} {short_name}")
                results['passed'] += 1
            else:
                print(f"  {Colors.RED}[FAIL]{Colors.ENDC} {short_name}: {error}")
                results['failed'] += 1
                results['failed_modules'].append((module, error))

        print()

    # Summary
    total = results['passed'] + results['failed']
    print(f"{Colors.BOLD}{'='*70}")
    print("SUMMARY")
    print(f"{'='*70}{Colors.ENDC}")
    print(f"  Total modules tested: {total}")
    print(f"  {Colors.GREEN}Passed: {results['passed']}{Colors.ENDC}")
    print(f"  {Colors.RED}Failed: {results['failed']}{Colors.ENDC}")

    if results['failed'] > 0:
        print(f"\n{Colors.RED}Failed modules:{Colors.ENDC}")
        for mod, err in results['failed_modules']:
            print(f"  - {mod}: {err}")

    # Test specific functionality
    print(f"\n{Colors.BOLD}{'='*70}")
    print("FUNCTIONAL TESTS")
    print(f"{'='*70}{Colors.ENDC}")

    # Test pandas operations
    try:
        import pandas as pd
        import numpy as np
        df = pd.DataFrame(np.random.randn(10, 5))
        df2 = pd.concat([df, df], ignore_index=True)  # Modern pandas
        print(f"  {Colors.GREEN}[OK]{Colors.ENDC} Pandas concat operations")
    except Exception as e:
        print(f"  {Colors.RED}[FAIL]{Colors.ENDC} Pandas operations: {e}")

    # Test dash imports
    try:
        from dash import html, dcc
        print(f"  {Colors.GREEN}[OK]{Colors.ENDC} Dash modern imports")
    except Exception as e:
        print(f"  {Colors.RED}[FAIL]{Colors.ENDC} Dash imports: {e}")

    # Test neo4j driver
    try:
        import neo4j
        print(f"  {Colors.GREEN}[OK]{Colors.ENDC} Neo4j driver (v{neo4j.__version__})")
    except Exception as e:
        print(f"  {Colors.RED}[FAIL]{Colors.ENDC} Neo4j driver: {e}")

    # Test analytics
    try:
        from sklearn.decomposition import PCA
        from sklearn.cluster import KMeans
        import umap
        print(f"  {Colors.GREEN}[OK]{Colors.ENDC} ML libraries (sklearn, umap)")
    except Exception as e:
        print(f"  {Colors.RED}[FAIL]{Colors.ENDC} ML libraries: {e}")

    # Test visualization
    try:
        import plotly
        import networkx
        import matplotlib
        print(f"  {Colors.GREEN}[OK]{Colors.ENDC} Visualization (plotly, networkx, matplotlib)")
    except Exception as e:
        print(f"  {Colors.RED}[FAIL]{Colors.ENDC} Visualization: {e}")

    print(f"\n{Colors.BOLD}{'='*70}{Colors.ENDC}")

    if results['failed'] == 0:
        print(f"{Colors.GREEN}{Colors.BOLD}ALL TESTS PASSED!{Colors.ENDC}")
        return 0
    else:
        print(f"{Colors.RED}{Colors.BOLD}SOME TESTS FAILED{Colors.ENDC}")
        return 1

if __name__ == '__main__':
    sys.exit(run_tests())
