import json
import logging
from pathlib import Path

import pytest
import yaml

from ckg import ckg_utils


def test_paths_follow_checkout_from_other_working_directory(tmp_path, monkeypatch):
    monkeypatch.delenv('CKG_CONFIG_FILE', raising=False)
    monkeypatch.delenv('CKG_ROOT', raising=False)
    monkeypatch.chdir(tmp_path)
    root = Path(ckg_utils.__file__).resolve().parent.parent
    config = ckg_utils.read_ckg_config()
    assert config['data_directory'] == str(root / 'data')
    assert config['imports_experiments_directory'] == str(root / 'data/imports/experiments')
    assert Path(config['graphdb_builder_log']).is_file()


def test_runtime_root_does_not_relocate_package_resources(tmp_path, monkeypatch):
    monkeypatch.delenv('CKG_CONFIG_FILE', raising=False)
    monkeypatch.setenv('CKG_ROOT', str(tmp_path))
    config = ckg_utils.read_ckg_config()
    assert config['log_directory'] == str(tmp_path / 'log')
    assert config['ckg_directory'] == str(Path(ckg_utils.__file__).parent)
    assert Path(config['report_manager_log']).is_file()


def test_custom_absolute_paths_are_preserved(tmp_path, monkeypatch):
    path = tmp_path / 'config.yml'
    path.write_text(yaml.safe_dump({'data_directory': '/custom/data', 'version': 1}))
    monkeypatch.setenv('CKG_CONFIG_FILE', str(path))
    assert ckg_utils.read_ckg_config('data_directory') == '/custom/data'
    with pytest.raises(KeyError):
        ckg_utils.read_ckg_config('missing')


def test_logging_creates_directory_under_runtime_root(tmp_path, monkeypatch):
    monkeypatch.delenv('CKG_CONFIG_FILE', raising=False)
    monkeypatch.setenv('CKG_ROOT', str(tmp_path))
    # Keep the test's logging configuration independent of pytest handlers.
    config = tmp_path / 'log.json'
    config.write_text(json.dumps({
        'version': 1, 'disable_existing_loggers': False,
        'handlers': {'file': {'class': 'logging.FileHandler', 'filename': 'test.log'}},
        'loggers': {'ckg-test': {'handlers': ['file'], 'level': 'INFO', 'propagate': False}},
    }))
    logger = ckg_utils.setup_logging(str(config), key='ckg-test')
    logger.info('portable logging')
    assert 'portable logging' in (tmp_path / 'log/test.log').read_text()
    for handler in logger.handlers[:]:
        handler.close()
        logger.removeHandler(handler)
