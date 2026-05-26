# simple_scheduler
The "simple_scheduler" provides very simple job and task orchestration.  It only supports sequential task execution as part of a job.  There is no built-in support for parallel scheduling (This is a different scheduling engine and is not open-source)

## Deployment
Requires `CORE` 3.3.0 or later and `UTL_INTERVAL` 1.0.0 or later. Deploy with the source commit hash as the first SQLPlus argument:

```sql
@Deployment_Manifests/deploy.sql <commit-hash>
```

## Maven Packaging
Build a repository ZIP for Maven-based distribution with:

```sh
mvn package
```

This creates `target/simple_scheduler-1.1.0.zip` and includes generated
build provenance at `META-INF/simple_scheduler-build.properties`.

See [Maven Packaging](docs/maven-packaging.md) for details.
