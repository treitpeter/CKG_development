from unittest.mock import Mock

import pytest

from ckg.report_manager import index


def test_homepage_serves_without_starting_workers():
    assert index.application.test_client().get('/').status_code == 200


@pytest.mark.parametrize('route,key,filename', [
    ('/downloads/demo', 'downloads_directory', 'demo.zip'),
    ('/example_files', 'data_directory', 'example_files.zip'),
    ('/tmp/project_demo', 'tmp_directory', 'Uploaded_files_demo.zip'),
])
def test_downloads_use_current_flask_api(tmp_path, monkeypatch, route, key, filename):
    monkeypatch.setitem(index.ckg_config, key, str(tmp_path))
    (tmp_path / filename).write_bytes(b'archive fixture')
    with index.application.test_client().get(route) as response:
        assert response.status_code == 200
        assert response.data == b'archive fixture'
        assert 'attachment;' in response.headers['Content-Disposition']


def test_workers_use_same_interpreter_and_stop_when_server_exits(monkeypatch):
    workers = [Mock(), Mock(), Mock()]
    popen = Mock(side_effect=workers)
    monkeypatch.setattr(index.subprocess, 'Popen', popen)
    monkeypatch.setattr(index.application, 'run', Mock(side_effect=RuntimeError('server stopped')))
    with pytest.raises(RuntimeError, match='server stopped'):
        index.main()
    assert popen.call_count == 3
    for call in popen.call_args_list:
        assert call.args[0][:3] == [index.sys.executable, '-m', 'celery']
    for worker in workers:
        worker.terminate.assert_called_once()
        worker.wait.assert_called_once_with(timeout=10)
