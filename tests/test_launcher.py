from pathlib import Path
import shutil
import subprocess
import os
import sys
import pytest

ROOT = Path(__file__).resolve().parents[1]


def test_status_reports_all_services_when_stopped(tmp_path):
    script = tmp_path / 'start.sh'
    shutil.copyfile(ROOT / 'start.sh', script)
    result = subprocess.run(['bash', str(script), 'status'], capture_output=True, text=True)
    assert result.returncode == 1
    assert result.stdout.splitlines() == ['Redis: STOPPED', 'Neo4j: STOPPED', 'CKG Web: STOPPED']


def test_start_fails_before_starting_services_when_dependencies_missing(tmp_path):
    script = tmp_path / 'start.sh'
    shutil.copyfile(ROOT / 'start.sh', script)
    result = subprocess.run(['bash', str(script), 'start'], capture_output=True, text=True)
    assert result.returncode == 1
    assert 'Run ./install.sh' in result.stderr
    assert not (tmp_path / 'run').exists()


def test_missing_command_prints_usage(tmp_path):
    script = tmp_path / 'start.sh'
    shutil.copyfile(ROOT / 'start.sh', script)
    result = subprocess.run(['bash', str(script)], capture_output=True, text=True)
    assert result.returncode == 1
    assert 'Usage:' in result.stderr


def test_reinstall_from_other_directory_preserves_credentials(tmp_path):
    root = tmp_path / 'checkout with spaces'
    root.mkdir()
    shutil.copyfile(ROOT / 'install.sh', root / 'install.sh')
    connector_dir = root / 'ckg/graphdb_connector'
    connector_dir.mkdir(parents=True)
    config = connector_dir / 'connector_config.yml'
    original = 'db_password: "existing-private-password"\n'
    config.write_text(original)
    redis = root / 'redis/redis-stable/src'
    redis.mkdir(parents=True)
    (redis / 'redis-server').touch()
    neo4j = root / 'neo4j/neo4j-community-5.26.0/conf'
    neo4j.mkdir(parents=True)
    (neo4j / 'neo4j.conf').write_text('# deployment-specific configuration\n')
    venv = root / 'venv/bin'
    venv.mkdir(parents=True)
    # No installation, network access or service process in this regression.
    (venv / 'activate').write_text('python() { cat >/dev/null; return 0; }\n')
    env = {**os.environ, 'PYTHON': sys.executable}
    result = subprocess.run(['bash', str(root / 'install.sh')], cwd=tmp_path,
                            env=env, input='', capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
    assert config.read_text() == original
    assert (neo4j / 'neo4j.conf').read_text() == '# deployment-specific configuration\n'


@pytest.mark.parametrize('pid,should_stop', [('1234', True), ('9999', False)])
def test_stop_only_shuts_down_redis_with_matching_owned_pid(tmp_path, pid, should_stop):
    shutil.copyfile(ROOT / 'start.sh', tmp_path / 'start.sh')
    run = tmp_path / 'run'
    run.mkdir()
    (run / 'redis.pid').write_text(pid + '\n')
    cli = tmp_path / 'redis/redis-stable/src/redis-cli'
    cli.parent.mkdir(parents=True)
    cli.write_text('''#!/bin/bash
case "$*" in
    *ping) echo PONG ;;
    *"info server") echo process_id:1234 ;;
    *shutdown) touch redis-stopped ;;
esac
''')
    cli.chmod(0o755)
    result = subprocess.run(['bash', str(tmp_path / 'start.sh'), 'stop'],
                            capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
    assert (tmp_path / 'redis-stopped').exists() == should_stop
