# Database downloads

CKG does not distribute a preloaded graph or copies of external databases.

Database parsers and source configuration are in
`ckg/graphdb_builder/databases/parsers/` and
`ckg/graphdb_builder/databases/config/`. Review the relevant source's current
download documentation, access conditions and schema before building a graph.
Some sources require an account or a license; supply credentials through your
own deployment and do not commit them.

After installing CKG, a local build can be started with:

```bash
source venv/bin/activate
python scripts/build_database_graceful.py
```

This is a substantial data operation: inspect the script and database
configuration first. The script attempts multiple sources and records failures
individually. A successful Python installation does not imply that every remote
download endpoint remains available.

Use `python -m pytest --run-network` for the legacy URL checks. They are separate
from offline CI, may depend on access rights, and are not an end-to-end parser or
graph validation. Record the retrieval date, source version, checksums, parser
version and counts for every scientific analysis built from the graph.

Scheduler resources, storage locations and service settings belong in your
deployment configuration. No institution-specific job scripts are distributed.
