# multicloud-gitops-extension

This repository is a thin Validated Patterns wrapper that reuses upstream `clustergroup` chart logic and points applications to upstream (or customer-forked) Git repositories.

The goal is to keep the local repo as values-only as possible:

- `Chart.yaml` depends on upstream `clustergroup`
- `values-global.yaml` defines global pattern settings
- `values-hub.yaml` defines `clusterGroup.applications` entries and their `repoURL`/`targetRevision`/`path`

## Upstream baseline

This extension is designed to layer on top of the upstream Multicloud GitOps pattern model:

- https://validatedpatterns.io/patterns/multicloud-gitops/

## Prerequisites

- An OpenShift hub cluster.
- Cluster-admin access (`oc whoami` can perform cluster-wide actions).
- Validated Patterns Operator already installed.
- Helm 3.x installed locally for fallback install flow.

## Configure values

1. Set your hub domain in `values-global.yaml`:

   ```yaml
   global:
     hubClusterDomain: apps.<your-domain>
   ```

2. Update application repository pointers in `values-hub.yaml` as needed:
   - `tenancy-base`, `tenancy-placements`, and AC/CM/SC policy apps default to upstream `multicloud-gitops`.
   - `tenant-form-acm-gui` is a placeholder and should point to your GUI repo/fork.

## Install from a bare cluster (operator primary path)

Use a Pattern custom resource so installation stays operator-managed.

1. Create/edit `examples/pattern-cr.yaml` for your org/repo/branch.
2. Apply the CR:

   ```bash
   oc apply -f examples/pattern-cr.yaml
   ```

3. Watch reconciliation:

   ```bash
   oc get pattern -A
   oc get applications -n openshift-gitops
   ```

4. Verify expected artifacts:

   ```bash
   oc get appproject -n openshift-gitops
   oc get consoleplugins
   ```

## Helm fallback path

If you need a direct Helm-driven workflow:

```bash
helm dependency build
helm template multicloud-gitops-extension . \
  -f values-global.yaml \
  -f values-hub.yaml > rendered.yaml
oc apply -f rendered.yaml
```

## Validation checks

Run after either install path:

```bash
oc get applications -n openshift-gitops
oc get policies -A
oc get consoleplugins
```

## Uninstall

Operator path:

```bash
oc delete -f examples/pattern-cr.yaml
```

Helm fallback path:

```bash
oc delete -f rendered.yaml --ignore-not-found=true
```


