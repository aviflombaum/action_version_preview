# Releasing ActionVersionPreview

Use this procedure to publish a tested gem and then attach a GitHub tag/release
to the exact source revision used to build it. RubyGems publication is performed
manually by the maintainer.

## Prepare and validate

1. Audit the local and remote release branches. Merge all intended changes into
   the release branch, including any new commits from remote `main`.
2. Update `lib/action_version_preview/version.rb`, the local gem entry in
   `Gemfile.lock`, the changelog, README, usage guide, and release notes.
3. Run the checks below. Security tools are maintainer tools, not runtime gem
   dependencies. Use current installed versions and an updated advisory database.

```sh
bundle check
bin/rails test
CI=true bin/rails test
bin/rubocop
RAILS_ENV=test bundle exec rake app:zeitwerk:check
bundle-audit check --update
brakeman --force-scan --no-pager .
brakeman --no-pager --add-engines-path ../.. --gemfile ../../Gemfile test/dummy
erb_lint --lint-all --enable-linters erb_safety,parser_errors
npx --yes markdownlint-cli2@0.23.2 README.md CHANGELOG.md SUGGESTIONS.md docs/usage.md docs/releasing.md docs/releases/0.2.0.md
git diff --check
```

The test suite builds and installs the gem into a temporary directory, checks
early loading/reloading, renders the real helper, and compiles a production asset
with `SECRET_KEY_BASE_DUMMY=1`. Brakeman needs the relative `../../Gemfile` argument
to identify the dummy app's shared dependency resolution correctly.

Check Markdown and all local/public documentation links as part of release
preparation. Avoid treating a remote server's rate limit as a broken link without
checking it separately.

## Merge and build

After validation, commit the release changes, merge the release branch into
`main`, and push `main`. Wait for GitHub CI to pass before publication. Verify that
each intended release-branch tip is an ancestor of `main`.

From a clean `main` checkout:

```sh
git rev-parse HEAD
bundle exec rake build
shasum -a 256 pkg/action_version_preview-0.2.0.gem
```

Record that commit SHA and the gem's checksum. Inspect the archive for the runtime
files, helper partial, license, README, changelog, and public documentation. It
must not contain development credentials, generated assets, tests, or research
notes. Check that packaged files are readable by other users.

## Maintainer publishes to RubyGems

Use the already-built artifact:

```sh
gem push pkg/action_version_preview-0.2.0.gem
```

Complete RubyGems authentication/MFA as prompted. See the official
[RubyGems publishing guide](https://guides.rubygems.org/publishing/) for account
setup. Do not rebuild or change the release commit after this artifact is pushed.

## Verify publication, then tag and release on GitHub

Confirm RubyGems lists version 0.2.0 and compare its SHA-256 with the local artifact.
The version API provides the published checksum:

```text
https://rubygems.org/api/v2/rubygems/action_version_preview/versions/0.2.0.json
```

Then use the recorded release commit, rather than assuming `main` has not moved:

```sh
git tag -a v0.2.0 RELEASE_COMMIT_SHA -m "ActionVersionPreview 0.2.0"
git push origin v0.2.0
gh release create v0.2.0 pkg/action_version_preview-0.2.0.gem \
  --verify-tag \
  --repo aviflombaum/action_version_preview \
  --title "ActionVersionPreview 0.2.0" \
  --notes-file docs/releases/0.2.0.md
```

Replace `RELEASE_COMMIT_SHA` with the recorded SHA. Inspect the resulting GitHub
release and verify its tag targets that commit. If a tag or release already
exists, inspect it before proceeding; do not move a published tag.

`bundle exec rake release` combines tagging, Git pushes, and RubyGems publication.
Do not use it for this staged workflow: the manual RubyGems push must happen before
the GitHub tag and release.
