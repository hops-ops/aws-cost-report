### What's changed in v0.2.1

* chore(makefile): add generate-configuration target (by @patrickleet)

  Wires hops validate generate-configuration as a prerequisite of
  validate:all / validate / validate:% so configuration.yaml is
  regenerated from upbound.yaml before each validation run.

  The `.gitignore` entry was auto-appended by the hops CLI on first
  run — configuration.yaml is a generated artifact.

  Implements [[tasks/update-xrd-makefiles-generate-config]]

* fix: automate tested dependency updates (by @patrickleet)

  * fix: automate tested dependency updates

  * fix: bound dependencies below next major

  * fix: avoid overlapping Renovate extraction

  * fix: address dependency review findings

  * fix: scope package dependency extraction

  * fix: validate Renovate configuration changes

  * fix: use compatible major dependency ranges


See full diff: [v0.2.0...v0.2.1](https://github.com/hops-ops/aws-cost-report/compare/v0.2.0...v0.2.1)
