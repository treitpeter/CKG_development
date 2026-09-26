"""Prevent machine-specific paths, saved execution outputs and keys in releases."""
import json
from pathlib import Path
import re
import subprocess

import yaml

ROOT = Path(__file__).resolve().parents[1]
PRIVATE_PATTERNS = [
    re.compile(rb'/(?:fs/(?:gpfs[^/\s]*|pool)|Users|home)/[^\s"\x27<>]+'),
    re.compile(rb'gh[pousr]_[A-Za-z0-9]{30,}'),
    re.compile(rb'-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----'),
]


def tracked_files():
    names = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode().split('\0')
    return [ROOT / name for name in names if name and (ROOT / name).is_file()]


def test_public_tree_has_no_machine_paths_or_private_keys():
    violations = []
    for path in tracked_files():
        data = path.read_bytes()
        if any(pattern.search(data) for pattern in PRIVATE_PATTERNS):
            violations.append(str(path.relative_to(ROOT)))
    assert not violations, 'Review public files: ' + ', '.join(violations)


def test_notebooks_contain_no_saved_outputs():
    for path in tracked_files():
        if path.suffix == '.ipynb':
            notebook = json.loads(path.read_text())
            for cell in notebook.get('cells', []):
                assert not cell.get('outputs'), str(path.relative_to(ROOT))
                assert cell.get('execution_count') is None, str(path.relative_to(ROOT))


def test_no_database_password_is_shipped():
    config = yaml.safe_load((ROOT / 'ckg/graphdb_connector/connector_config.yml').read_text())
    assert not config['db_password']
