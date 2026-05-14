# Quarter

**Quarter** is a distinct [Validated Pattern](https://validatedpatterns.io/) for OpenShift hub GitOps. It carries the [Multicloud GitOps](https://validatedpatterns.io/patterns/multicloud-gitops/) (MCG) hub layout (operators, subscriptions, clustergroup-driven `Application` CRs) and adds ACM tenancy GitOps (`tenancy-by-acm-policy`, `tenant-form-acm-gui`) on top.

## Lineage and upstream pin

- Upstream pattern repository: [validatedpatterns/multicloud-gitops](https://github.com/validatedpatterns/multicloud-gitops).
- The git ref we overlay is recorded in [deps/mcg-ref.txt](deps/mcg-ref.txt) (branch or tag). Bump that file when you intentionally move to a newer MCG baseline, then re-run CI and validate on a lab cluster.
- `pattern-metadata.yaml` and this README document that relationship; **CI** merges [values-global.yaml](values-global.yaml) + [values-hub.yaml](values-hub.yaml) and validates the result against the published [clustergroup-chart `values.schema.json`](https://github.com/validatedpatterns/clustergroup-chart/blob/main/values.schema.json) (same approach as upstream MCG’s jsonschema workflow).

## Repository layout (thin `main` vs install branch)

- **`main`**: Quarter-only artifacts — metadata, values, Pattern CR example, optional console manifests, scripts, and workflows.
- **`pattern-install`**: **Generated** full MCG tree with Quarter files copied on top (see [scripts/render-mcg-overlay.sh](scripts/render-mcg-overlay.sh) and [.github/workflows/render-mcg-overlay.yaml](.github/workflows/render-mcg-overlay.yaml)). The Validated Patterns Operator should use this branch so it receives a complete pattern repo (including `pattern.sh`, `charts/`, `common/`, etc.).

After your first changes land on `main`, open **Actions → Render MCG overlay to pattern-install** and run the workflow once if `pattern-install` does not exist yet. Subsequent pushes to the paths listed in that workflow update the branch.

## Prerequisites

- OpenShift hub cluster with cluster admin.
- [Validated Patterns Operator](https://validatedpatterns.io/learn/using-validated-pattern-operator/) installed.

## Install

```bash
oc apply -f examples/pattern.yaml
```

Watch reconciliation:

```bash
oc get pattern -n patterns-operator
oc get applications.argoproj.io -n quarter-hub
```

Argo CD for this pattern is the **pattern-scoped** instance in `quarter-hub` (for example `hub-gitops` in namespace `quarter-hub`), not the default `openshift-gitops` namespace.

## Uninstall

```bash
oc delete -f examples/pattern.yaml
```

## Optional: OpenShift console plugin for tenant GUI

After GitOps has created `quarter-hub` and the tenant GUI namespace, you can enable the console plugin and set the deployment image:

```bash
oc apply -f examples/console-plugin-enable.yaml
```

Edit the image in that file if you do not use the default `quay.io/ngner/tenant-form-acm-gui:latest`.

## Secrets and domains

Follow upstream MCG for `values-secret.yaml` and hub domain overrides; use the **rendered** tree on `pattern-install` and the upstream [values-secret.yaml.template](https://github.com/validatedpatterns/multicloud-gitops/blob/main/values-secret.yaml.template) as references.

## Policy Generator

[values-hub.yaml](values-hub.yaml) configures a `policy-generator` config-management plugin on the pattern Argo CD instance. Confirm the **image tag** matches your RHACM / OpenShift GitOps versions ([integrating Policy Generator](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html/governance/integrating-policy-generator)).

## Testing policy

- **Pull requests / pushes to `main`**: [.github/workflows/validate-values.yaml](.github/workflows/validate-values.yaml) merges `values-global.yaml` + `values-hub.yaml` and validates against the clustergroup schema (mirrors upstream MCG jsonschema checks).
- **Release discipline**: when you change [deps/mcg-ref.txt](deps/mcg-ref.txt), run the render workflow and exercise a hub install in a lab cluster before promoting.

Pursuing a formal **tested** Validated Pattern tier is separate from this repo’s CI and follows Red Hat’s current contribution and tier process.

## Local render (optional)

```bash
./scripts/render-mcg-overlay.sh
# Inspect ./build/mcg-overlay — full MCG clone with Quarter values on top
```
