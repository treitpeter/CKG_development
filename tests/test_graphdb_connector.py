from unittest.mock import patch

import pytest

from ckg.graphdb_connector import connector


def test_environment_overrides_credentials_without_rewriting_config(monkeypatch):
    original = connector.read_config()
    monkeypatch.setenv('CKG_DB_PASSWORD', 'test-override')
    monkeypatch.setenv('CKG_DB_PORT', '17687')
    config = connector.read_config()
    assert config['db_password'] == 'test-override'
    assert config['db_port'] == 17687
    monkeypatch.delenv('CKG_DB_PASSWORD')
    monkeypatch.delenv('CKG_DB_PORT')
    assert connector.read_config() == original


def test_invalid_driver_returns_none_instead_of_unbound_variable():
    with patch.object(connector.neo4j.GraphDatabase, 'driver', side_effect=ValueError('bad URI')):
        assert connector.connectToDB() is None


def test_invalid_configuration_preserves_original_error():
    with patch.object(connector.ckg_utils, 'get_configuration', side_effect=ValueError('bad config')):
        with pytest.raises(ValueError, match='bad config'):
            connector.read_config()
