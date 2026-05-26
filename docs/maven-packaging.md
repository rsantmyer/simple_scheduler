# Maven Packaging

This repository is an Oracle PL/SQL/database tooling project, not a Java library.
Maven is used here for versioning, dependency metadata, artifact distribution,
and future dependency resolution between database repositories.

The initial distributable artifact is a ZIP archive of the repository contents:

```text
target/simple_scheduler-1.1.0.zip
```

The ZIP includes source code, install/deployment scripts, documentation,
manifests, and demos. It excludes local build output, VCS metadata, GitHub
workflow metadata, IDE files, SQL*Plus spool logs, and temporary files.

## Local Build

From the repository root:

```sh
mvn package
```

This runs the Maven Assembly Plugin and creates:

```text
target/simple_scheduler-1.1.0.zip
```

The project uses `pom` packaging because Maven is serving as a metadata and
distribution tool. There is no Java compile step.

## Build Metadata

The Maven build generates a filtered properties file and packages it inside the
ZIP at:

```text
META-INF/simple_scheduler-build.properties
```

Example contents:

```properties
artifact.groupId=com.512itconsulting.database
artifact.artifactId=simple_scheduler
artifact.version=1.1.0
git.commit.id=5af0af4c86abef934e10e76744fcc05854dc580d
git.commit.id.abbrev=5af0af4
git.branch=main
git.dirty=true
build.time=2026-05-22T15:30:00Z
```

The Git values are generated dynamically from the current repository state by
`git-commit-id-maven-plugin`. Maven resource filtering combines those Git values
with artifact values from `pom.xml`; `build.time` comes from Maven's build
timestamp.

This supports deployment traceability without embedding Git hashes into the
Maven version string. Deployment tooling can inspect the ZIP and record exactly
which artifact coordinates and Git commit produced a deployed database state.

The `git.dirty` value is included as an additional traceability guard. A value
of `true` means the artifact was built with uncommitted working-tree changes, so
the commit hash alone does not fully describe the source content.

The plugin first writes Git metadata under `target/generated-git/`. The Maven
Resources Plugin then uses that file as a filter and creates the final metadata
file under `target/generated-build-metadata/`. The assembly descriptor places the
resolved file at `META-INF/simple_scheduler-build.properties` inside the final
ZIP. The template file under `assembly/` is excluded from the ZIP so the artifact
contains resolved metadata rather than unresolved Maven placeholders.

## Dependency Metadata

`simple_scheduler` declares Maven dependencies on:

```text
com.512itconsulting.database:core:0.1.0-SNAPSHOT
com.512itconsulting.database:utl_interval:1.0.0
```

This mirrors the database deployment dependencies on `CORE`, which provides
`pkg_application`, and `UTL_INTERVAL`, which provides interval aggregation used
by scheduler views. Maven does not understand PL/SQL install order by itself, so
the SQL deployment manifest remains the source of truth for object creation and
runtime validation.

## Publishing To GitHub Packages

The `pom.xml` publishes to GitHub Packages using this repository URL:

```text
https://maven.pkg.github.com/rsantmyer/simple_scheduler
```

Publish with:

```sh
mvn deploy
```

Maven will deploy the POM metadata and the attached ZIP artifact to GitHub
Packages.

GitHub Packages requires Maven credentials in `~/.m2/settings.xml`. The
`<server><id>` must match the repository id in `pom.xml`, which is currently
`github`.

Example:

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">
  <servers>
    <server>
      <id>github</id>
      <username>YOUR_GITHUB_USERNAME</username>
      <password>YOUR_GITHUB_TOKEN</password>
    </server>
  </servers>
</settings>
```

Use a GitHub personal access token with permission to publish packages for this
repository. For private package consumption, consumers will also need
credentials with package read access.

## Assumptions

- The package coordinates match the repository and application name:
  `com.512itconsulting.database:simple_scheduler:1.1.0`.
- The GitHub Packages owner/repository path is `rsantmyer/simple_scheduler`,
  matching the canonical GitHub owner for this repository.
- The ZIP preserves the repository's current layout instead of moving files into
  Maven's standard `src/main` tree.
- The ZIP includes Maven packaging files themselves because it is currently a
  repository-content distribution.
- `.claude/` is excluded as local tooling metadata, similar to IDE files.
