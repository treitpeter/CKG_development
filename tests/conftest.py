import pytest


def pytest_addoption(parser):
    parser.addoption('--run-network', action='store_true', help='Check external database URLs')


def pytest_collection_modifyitems(config, items):
    if not config.getoption('--run-network'):
        for item in items:
            if 'network' in item.keywords:
                item.add_marker(pytest.mark.skip(reason='Use --run-network for external URL checks'))
