# ActionVersionPreview 0.2.0 review and recommended updates

Reviewed: 2026-09-15  
Source revision: `12d2743e7ab144eb76eaefa64fe4e0716ea53186`  
Scope: the complete gem implementation, gemspec, current dependency resolution, tests, dummy application, CI, README, changelog, and feature suggestions.

This is a research and implementation backlog. The first-priority helper-loading fix and item 1 (safe switcher URLs) have been implemented locally for 0.2.0, as recorded below; the other recommendations remain backlog items. The working tree already contained changes to `Gemfile.lock`; this review used and preserved that resolution.

## Summary

First priority for 0.2.0: fix and regression-test the published 0.1.0 helper-loading bug that blocks PostMoney staging builds. Then prioritize safe switcher URLs, malformed input handling, access-check ordering, and actual switcher integration tests. Then make discovery and compatibility promises match what is tested. The existing implementation is small and easy to follow; keep the native Rails variant mechanism, ordinary links, default production denial, and request-local discovery memoization.

| Priority | Recommendation | Evidence |
| --- | --- | --- |
| P1 — first | Fix the 0.1.0 helper-loading failure during application boot | Published package reproduces PostMoney’s error; current checkout passes the same isolated boot probe |
| P1 | Keep switcher links on the current application path | Reproduced external links from user-supplied URL options |
| P2 | Validate preview parameter shape before conversion | Reproduced exceptions for array and hash inputs |
| P2 | Define when access checks run relative to host authentication | Reproduced default rendering with preview reported active |
| P2 | Cover the rendered switcher and its navigation | No existing test renders the helper; Default removes preview mode |
| P2 | Align discovery with supported Rails template paths and names | Reproduced renderable but undiscoverable variant |
| P2 | Test the advertised Ruby/Rails range | CI has one combination; dummy app uses newer Rails APIs |
| P2 | Correct documentation about integrations and access boundaries | README and suggestions exceed the implemented guarantees |
| P3 | Improve switcher accessibility, packaging, and contributor instructions | Source inspection and gem-build warnings |

P1 means address before releasing the affected functionality. P2 means a correctness, compatibility, or meaningful coverage gap. P3 means a useful improvement that need not block the release.

## Validation performed at initial review

Environment: Ruby **4.0.5**, Bundler **2.7.2**, Rails **8.1.3.1**, macOS arm64. These results do not establish compatibility with every version allowed by the gemspec.

| Check | Result |
| --- | --- |
| `bundle check` | Dependencies satisfied |
| `bin/rails test` | 14 tests, 41 assertions; no failures, errors, or skips |
| `CI=true bin/rails test` | 14 tests, 41 assertions; passes with eager loading enabled |
| `bin/rubocop` | 40 files inspected; no offenses |
| `RAILS_ENV=test bundle exec rake app:zeitwerk:check` | Passes |
| `bundle-audit check --update` | No known vulnerabilities found in the working lockfile |
| `gem build action_version_preview.gemspec --output /tmp/action_version_preview-review-0.1.0.gem` | Builds; file-permission and duplicate-URI warnings |
| Isolated integration probes | Confirmed URL manipulation, malformed input exceptions, discovery limitations, Default navigation behavior, and callback-order inconsistency |

The advisory database revision was `f08b5bf5b2778201db0b69f0faa7a407e2476cb8`, last updated September 13, 2026. This is a known-advisory check of resolved dependencies, not a source audit of every transitive gem or proof of security. The audit tool was already installed; it is not declared in this repository.

The engine-root command `bin/rails zeitwerk:check` was unrecognized; the namespaced Rake command above succeeds. Probe scripts and the built gem were kept outside the repository. No older-Rails matrix, production deployment, or browser accessibility/CSP test was run.

## First priority: fix the published 0.1.0 boot failure for 0.2.0

**Priority: P1 — release blocker, confirmed. Implementation complete locally; pending 0.2.0 release.**

Affected release: published `action_version_preview` **0.1.0**.  
Incident: PostMoney staging Docker build, September 15, 2026 at 21:51:23, during `SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile`.

The build failed while loading the Rails environment:

```text
NameError: uninitialized constant ActionVersionPreview::SwitcherHelper
Tasks: TOP => assets:precompile => environment
```

The published package’s `lib/action_version_preview/engine.rb:10` calls `helper ActionVersionPreview::Engine.helpers` inside the Action Controller load hook. When a host loads Action Controller before the main autoloader is set up, this eagerly resolves the helper constant before it is available. The helper file is present in the package; this is a load-order defect, not a missing-file diagnosis.

**Evidence:** the same exception and helper-resolution stack were reproduced with the installed 0.1.0 package in a minimal Rails 8.1.3.1 application, independently of PostMoney. The package SHA-256, `849d78ff1a08646eb254d67f9bb98f4793a79fa199e6ea87c69733e4a1830fd6`, matches PostMoney’s lockfile. The probe loaded Action Controller during initialization before `setup_main_autoloader`.

The current checkout contains commit `12d2743` ("Fix load order of helpers to not conflict with earlier middleware") and passes the same isolated boot probe. Its version constant is still 0.1.0, but its helper-loading implementation differs from the published 0.1.0 package. The earlier suite and build checks in this report exercised the checkout, so they did not validate the released artifact. PostMoney’s full Docker build was not rerun during this diagnosis.

**Required for 0.2.0:** include and validate the helper-loading fix in the 0.2.0 release. Treat this as a gem defect to resolve in 0.2.0; no PostMoney workaround or separate 0.1.x release is part of this backlog.

**Regression tests worth writing:**

- Boot a minimal host in a fresh process that loads Action Controller before the main autoloader setup; assert initialization succeeds.
- Run production-like `SECRET_KEY_BASE_DUMMY=1` asset precompilation in an isolated host without application secrets or external services.
- Build and install the candidate gem into an isolated environment and run the boot/precompile checks against that artifact, rather than only the repository path dependency.
- After boot, render `variant_switcher` with `include_all_helpers = false` to verify the fix retains helper availability; cover eager loading and development reloading as applicable.

### Implementation update

Implemented via [the load-order plan](../../plans/2026-09-15-fix-helper-load-order.md). The regression tests exposed a further failure in the previously reviewed checkout: when Action View was already loaded, its replacement load hook still resolved `SwitcherHelper` before main autoloading was ready. Three of the four new boot tests failed before the fix.

The helper now lives in `lib/action_version_preview/switcher_helper.rb` and is explicitly required by the engine before hooks are registered. It remains a stable module across development reloads. Fresh-process tests cover early and lazy framework loading, rendering after reload, and a built/installed gem's production asset-precompile task with `SECRET_KEY_BASE_DUMMY=1`. The host renders the real engine partial with `include_all_helpers = false`, and package checks verify the engine and helper originate in the installed payload.

After the load-order fix, the full suite contained 18 tests and 45 assertions. Normal and CI/eager-loading runs pass, as do RuboCop and the Zeitwerk check. This validates the local implementation on Ruby 4.0.5 / Rails 8.1.3.1; PostMoney's full Docker build and the broader compatibility matrix remain unrun. No release has been published.

This first-priority implementation is complete locally. Subsequent implementation progress is recorded under the relevant backlog items below.

## 1. Build switcher URLs from the current path and query data

**Priority: P1 — confirmed. Implemented locally; pending 0.2.0 release.**

Original source: `app/views/action_version_preview/_variant_switcher.html.erb:5` and `:9`.

At review time, both links passed `request.params` directly into `url_for`. Rails interprets keys such as `host`, `protocol`, and `script_name` as URL-generation options. They do not remain ordinary filter values. This matches the documented [Rails URL-generation options](https://api.rubyonrails.org/classes/ActionDispatch/Routing/UrlFor.html).

With the switcher rendered, the following request:

```text
/posts?vv=v2&host=attacker.example&protocol=https
```

produced:

```text
Default  -> https://attacker.example/posts
REDESIGN -> https://attacker.example/posts?vv=redesign
V2       -> https://attacker.example/posts?vv=v2
```

`script_name=/unexpected` similarly changed the generated path prefix. This is link-destination manipulation requiring the preview widget to be visible and someone to follow a link; no automatic redirect or code execution was demonstrated.

**Recommended change:** move URL construction into a focused helper. Preserve the current local request path, encode `request.query_parameters` as query data, and replace/remove only the configured preview key. Do not pass arbitrary query keys as routing options. Preserve mounted-application prefixes and nested query values. Avoid including POST bodies in generated GET URLs: `request.params` also contains body and routing parameters.

**Tests worth writing:** malicious URL-option keys cannot change origin/path; nested filters and pagination survive; the configured preview key appears once; mounted paths survive; body fields do not leak into links when rendering a form response. Assert parsed URLs and query hashes rather than query-string ordering.

### Implementation update

Implemented on `release-0-2-0/safe-switcher-urls` using [the safe-URL plan](../../plans/2026-09-15-safe-switcher-urls.md). Both links now call a private helper that preserves `request.path` and encodes only `request.query_parameters`, replacing/removing the configured preview key. Query keys cannot become routing options, body fields are excluded, and Default retains its existing behavior.

Three integration tests cover hostile URL-option keys and nested filters, string/symbol parameter configuration with a mounted prefix, and POST-body exclusion. The dummy layout now renders the switcher. The full suite passes with 21 tests and 101 assertions, including the installed-gem boot/precompile regression; RuboCop reports 43 files with no offenses. Other switcher UX and visibility coverage in item 4 remains separate work.

## 2. Validate preview input before calling `to_sym`

**Priority: P2 — confirmed.**  
Source: `lib/action_version_preview/controller_methods.rb:15–21`.

`present?` does not establish that a parameter is a string. Authorized requests to `/posts?vv[]=v2` and `/posts?vv[name]=v2` raise `NoMethodError` on `to_sym` for `Array` and `ActionController::Parameters`, respectively. Production denial currently avoids conversion, but any enabled preview environment is affected.

**Recommended change:** accept a scalar string, handle blank values and the exact `true` sentinel explicitly, and choose a consistent invalid-input policy. Ignoring malformed preview input and rendering the normal page is a reasonable default for this optional feature. Make `variant_preview_active?` use the same validity rules. Do not stringify arbitrary arrays/hashes or add a broad exception rescue.

Decide whether names have a documented syntax/length limit. Do not require membership in the current `detected_variants` result: its current incomplete scan would reject valid layout, partial, or custom-path variants. Unknown scalar variants presently fall back to the ordinary action template when it exists; preserve or explicitly document a change to that behavior.

**Tests worth writing:** missing, empty, whitespace-only, array, hash, normal string, unknown string, and `true` inputs; repeat key cases with a custom parameter name and access denied. Verify denied input never changes an existing application-assigned variant.

## 3. Establish an access-check and callback-order contract

**Priority: P2 — confirmed integration edge case.**  
Sources: `lib/action_version_preview/engine.rb:8`, `controller_methods.rb:9`, `:18`, `:30`, and `:48`.

The preview callback is installed on `ActionController::Base`, before callbacks subsequently declared by host controllers. An access check that depends on state populated by a host `before_action` can therefore run too early. Reproduction with a host callback assigning `@preview_allowed = true` and a checker reading that variable produced the default template, `current_variant == nil`, and `variant_preview_active? == true` on the same `?vv=v2` request. The later helper check sees different state from the earlier selection check.

This does not establish that a lazily evaluated `current_user` method is broken. It specifically affects authentication/context setup performed in later callbacks.

**Recommended change:** document and test the callback ordering requirement, and provide an explicit way to place preview selection after host authentication if needed. Prefer a gem-specific private callback name to reduce collisions with a host method named `set_view_variant`. Only consider memoizing access decisions once their timing is settled; caching an early denial would conceal the inconsistency without selecting the requested template. If memoized, preserve false/nil results rather than using `||=`.

**Tests worth writing:** production/staging defaults deny; development/test defaults allow; a custom checker receives the actual controller; denied users get no widget and no variant override; callback-populated user/context state works through the documented integration; existing request variants survive absent/denied preview parameters. Use an isolated process or restored environment stub for default-environment tests.

## 4. Test the actual switcher and decide what Default means

**Priority: P2 — confirmed behavior and coverage gap.**  
Sources: `app/views/action_version_preview/_variant_switcher.html.erb:1–10`, `test/dummy/app/views/layouts/application.html.erb`, and `test/integration/variant_preview_test.rb`.

The dummy layout never calls `variant_switcher`. Existing integration tests inspect rendered headings and private helper methods, so neither the helper wiring nor the partial and its links are exercised by the suite. Rendering the helper in an isolated request worked, including with `include_all_helpers = false`.

The Default link removes `vv`. Following it makes the switcher disappear because visibility requires the parameter. This is consistent with the present visibility rule but interrupts repeated design comparisons.

**Recommended behavior:** make Default select the base view while retaining preview mode with the `true` sentinel; add a separate exit link if needed. Clarify that `true` preserves any host-assigned device variant—it does not force a completely unvarianted request. Treat this as a UX decision, not a previously promised behavior.

Unknown variant names can also leave no switcher item highlighted even when Rails renders the base template. Distinguish the requested variant from the template actually used in documentation or UI; `current_variant` currently reports the request, not resolver success.

**Tests worth writing:** show the widget only with permission, valid preview activation, and available variants; follow V2, Default, and exit links; assert selected-link semantics; render in a no-variants action; verify alternate configured parameter names end to end. Most of this belongs in fast integration tests, not browser automation.

## 5. Make discovery match the supported rendering scope

**Priority: P2 — confirmed limitations.**  
Source: `lib/action_version_preview/controller_methods.rb:34–43`.

Discovery scans only `Rails.root/app/views/<controller_path>/<action>.html+*.erb` and accepts names matching `\w+`. It misses:

- Templates in prepended/appended paths and engine-owned view directories.
- Locale-qualified files such as `index.en.html+localized.erb`.
- Names such as `new-design`, which Rails accepts.
- Other registered handlers such as Slim/Haml.
- Variants that exist only on a layout, partial, component, or explicitly rendered different template.

A temporary `prepend_view_path` containing `posts/index.html+new-design.erb` rendered successfully for `vv=new-design`, while discovery still returned only `redesign` and `v2`. The installed Rails resolver also parsed both the hyphenated and locale-qualified examples successfully. Rails documents native [variant selection and fallback](https://guides.rubyonrails.org/layouts_and_rendering.html#the-variants-option).

**Recommended change:** define the scope first. For 0.2.0, support action-template discovery across applicable filesystem view paths with locale/handler-aware parsing, or document the narrower scope precisely. Isolate any dependency on resolver internals behind a small adapter and compatibility tests. Do not promise arbitrary resolver enumeration. Consider an explicit variant list for component/layout-only cases instead of parsing ERB to infer render dependencies.

Deduplicate and sort results when expanding view paths. Keep discovery memoized per request; do not add global caching without a measured need and a development-reload invalidation design.

The four excluded names are this gem’s convention, not a Rails-enforced reserved namespace. `/posts?vv=mobile` successfully renders the mobile variant today; exclusion affects discovery only.

**Tests worth writing:** namespaced controllers, additional view roots, duplicate names, locale-qualified templates, hyphenated names, supported handlers, missing directories, and actual files for each excluded device variant. The present “excludes all standard Rails variants” test has only a mobile fixture; assertions for the other three do not demonstrate filtering.

## 6. Dependencies and compatibility

### Publish a tested support matrix

**Priority: P2.**  
Sources: `action_version_preview.gemspec:21–23`, `.github/workflows/ci.yml`, and the dummy application.

The gem advertises Ruby >= 3.1 and Rails >= 7.0, < 9.0. CI runs Ruby 3.4.7 against one lockfile resolution. The reviewed local resolution is Rails 8.1.3.1; its gem metadata requires Ruby >= 3.2. The locked sqlite3 2.9.6 also requires Ruby >= 3.2. The broad gemspec is not itself contradictory: Bundler may select older compatible dependencies. The single lockfile does not verify that promise.

The current harness cannot simply be used unchanged on every advertised Rails version: `config.autoload_lib` arrived in [Rails 7.1](https://guides.rubyonrails.org/7_1_release_notes.html#introducing-config-autoload-lib-and-config-autoload-lib-once-for-enhanced-autoloading), and `allow_browser` arrived in [Rails 7.2](https://guides.rubyonrails.org/7_2_release_notes.html#add-browser-version-guard-by-default). Other generated configuration should be checked during matrix boot. These are harness limitations, not evidence that the small runtime concern fails on older Rails.

**Recommended change:** use separate gemfiles or Appraisal for supported Rails series, with Ruby combinations each series can run. If preserving 7.0–8.x support, exercise 7.0, 7.1, 7.2, 8.0, and 8.1 at least once, plus the gem’s lowest declared Ruby and a current supported Ruby on compatible Rails. Give old combinations compatible development dependencies; do not resolve them against the Rails 8 lockfile. Run lint once on a maintained Ruby. Guard or remove unrelated modern dummy-app features.

Alternatively, narrow the advertised support deliberately and call it out as a compatibility change. Distinguish gem compatibility from upstream maintenance; Rails’ current [maintenance policy](https://guides.rubyonrails.org/maintenance_policy.html) limits security maintenance by release age.

### Reduce unnecessary dependency coupling where useful

**Priority: P3 — design improvement.**

The sole runtime dependency is the full `rails` metagem. This brings Active Record, Active Storage, Action Mailbox, Action Text, and other components the gem’s own code does not use. Evaluate declaring `railties`, `actionpack`, and `actionview` with aligned supported bounds; declare Active Support directly if retaining direct API use as an explicit dependency policy. Verify boot and rendering in a minimal app before changing the dependency declaration.

The root Gemfile’s `puma`, `sqlite3`, `propshaft`, and RuboCop stack support development and the dummy app; they are not direct runtime dependencies of the distributed gem. The dummy app uses `rails/all` and database fixture setup despite having no model behavior under test. Simplifying that harness could remove sqlite3/fixture setup, but retain an intentional full-Rails integration smoke test.

Keep weekly Bundler/GitHub Actions Dependabot updates. Add a reproducible `bundler-audit` CI check with an updated advisory database; Dependabot scheduling and an audit check serve different purposes. Avoid arbitrary version pins or upper bounds without a reproduced incompatibility. No emergency dependency upgrade is indicated by the audit performed here. [Bundler Audit documents its lockfile checks and database update command](https://github.com/rubysec/bundler-audit).

## 7. Documentation corrections

**Priority: P2/P3.**

1. **Separate rendering from discovery.** README’s statement that this works with layouts, partials, mailers, and ViewComponent templates needs qualification. Request variants can participate in rendering layouts/partials, but the switcher scans only action ERB templates. The engine hooks Action Controller, not Action Mailer; it does not automatically propagate a preview URL into mail jobs. ViewComponent has its own [variant template behavior](https://viewcomponent.org/guide/templates.html#variants); document supported/tested usage rather than implying component discovery exists.
2. **Replace “Zero dependencies.”** Say “No additional database or feature-flag service.” The gem has a Rails dependency.
3. **Correct the security claim in `SUGGESTIONS.md`.** The assertion that probing variants exposes nothing because Rails falls back is too broad: existing variants do render. `access_check` controls who may select a variant through this gem; hiding names from discovery does not deny selection, and preview selection is not authorization for the data/actions used by a template. Keep host authorization in place and explain the default production/staging denial.
4. **Explain request scope.** Selection does not persist automatically across links, redirects, forms, or background work. Define `vv=true`, missing/unknown names, device-variant interaction, and the meaning of `current_variant`.
5. **Document the callback contract.** Include the access-check timing requirement and the supported way to run after host authentication/context setup.
6. **Clarify the helper table.** `variant_switcher` is a view helper; the other listed methods are private controller methods exposed to views. “Available in controllers and views” is too broad for the whole table.
7. **Add contributor and release instructions.** Document setup, test/lint commands, matrix selection, a working eager-load command, and gem build. Add a 0.2.0 changelog entry when changes are implemented, with migration notes for changed Default behavior, accepted input, or supported versions. Keep proposed behavior clearly separate from shipped behavior.

## 8. Accessibility, packaging, and maintenance

**Priority: P3 unless a deployment depends on the affected behavior.**

- Give the switcher a labeled navigation region and expose the current choice with `aria-current`. Active state currently relies on background color alone. Preserve visible keyboard focus and allow wrapping when many variants exist. Add a targeted keyboard/mobile check once the markup changes.
- Inline styles make customization awkward and can be blocked by a host policy that disallows style attributes. Offer documented classes/overrides or optional styling without forcing an asset-pipeline dependency. Test with an actual strict CSP if supporting that configuration; this review did not run a browser CSP test.
- Include `CHANGELOG.md` in the gem payload. The gemspec currently excludes it. Keep the runtime files and license included; consider filtering directory entries and unused scaffold files. RubyGems defines packaging and metadata options in its [specification reference](https://guides.rubygems.org/specification-reference/).
- The local gem build warned that `controller_methods.rb`, `switcher_helper.rb`, and the switcher partial were not world-readable; inspecting the archive confirmed mode `100600`. Normalize source permissions for packaging and inspect the built artifact on the release machine. A clean checkout may behave differently, so treat this as a local release-artifact finding, not a proven failure for every install. Do not change files to executable to solve readability.
- The duplicate homepage/source URI warning is cosmetic; use genuinely distinct links if available, or accept it intentionally.
- Remove the empty `navigation_test.rb` scaffold or populate it with the navigation tests above. Remove unused generated CI comments/tasks only as they stop helping maintainers; no framework rewrite is needed.

## 9. Recommended test implementation order

Prefer behavior assertions at the request boundary. Keep small configuration/discovery unit tests where they make unusual cases cheaper to cover. Avoid tests that merely repeat a constant’s contents or assert every private implementation detail.

| Order | Test group | Acceptance criteria |
| --- | --- | --- |
| 0 — first | Published-release boot regression | Candidate 0.2.0 package boots with early controller loading and completes isolated production-like asset precompilation |
| 1 | Switcher URL safety | Query keys cannot change link origin/path; filters survive; body data stays out |
| 2 | Input validation | Array/hash/blank values follow the documented policy without exceptions |
| 3 | Access decisions | Denied input never selects a variant or renders the widget; configured timing works |
| 4 | Real switcher integration | Render helper through a layout, follow links, and verify activation/current choice |
| 5 | Custom configuration | Custom string/symbol parameter names work for selection, detection UI, and links |
| 6 | Discovery | Supported view paths/names/locales/handlers are included exactly once and exclusions work |
| 7 | Existing host behavior | Existing device variants survive absent/denied input; `true` follows the documented rule |
| 8 | Compatibility/package smoke | Each declared Rails series boots/renders; packaged helper/partial load in a host app |

For configuration tests, restore both global settings in teardown or `ensure`, even when assertions fail. The existing `configure` test resets the value only after its assertion, which can contaminate later tests after a failure. Do not run tests mutating module configuration concurrently in threads without isolation.

A regression for the external-host issue should render the widget, request `?vv=v2&host=attacker.example&protocol=https`, and assert that every preview link retains the local destination. A malformed-input regression should make an actual Rack-parsed request such as `?vv[]=v2`; passing only ordinary scalar test parameters will miss the bug.

## Suggested 0.2.0 delivery sequence

1. Fix the published 0.1.0 helper-loading failure for 0.2.0 and add isolated boot/precompile regression coverage against the packaged gem.
2. Fix link generation and malformed input with regression tests.
3. Establish access-check timing and cover the real switcher through the dummy layout.
4. Decide Default/exit behavior and document request scope.
5. Expand discovery to the chosen support boundary and add fixtures for it.
6. Add the compatibility matrix, reproducible dependency audit, and package smoke check.
7. Update README, suggestions, changelog, and contributor instructions to match the released behavior.

Defer navigation persistence, localStorage, Stimulus, recursive partial scanning, and global discovery caches until there is a concrete requirement. The existing suggestions identify possible features; correctness and test coverage should come first for this release.
