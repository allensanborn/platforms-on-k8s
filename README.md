# Platform Engineering on Kubernetes :: Book Code / Tutorials / Examples

This repository contains all the source code, tutorials, and examples from the [Platform Engineering on Kubernetes](https://www.salaboy.com/books/) Book.

## What changed in this fork

This is a fork of [salaboy/platforms-on-k8s](https://github.com/salaboy/platforms-on-k8s), updated in September 2026 on the branch `crossplane-v2-and-bitnami-replacements`:

- Bitnami stopped publishing its versioned images in 2025, so the Conference application's Redis, PostgreSQL and Kafka no longer started. The chart now uses the official Valkey chart, a CloudNativePG `Cluster` and Strimzi Kafka, and it's published as `oci://ghcr.io/allensanborn/conference-app` version `v1.1.0`.
- Chapters 5 and 6 are rewritten for Crossplane v2 (namespaced XRs, function pipelines) and vcluster 0.37.
- Every change was tested on local kind clusters unless marked otherwise.

Read [`docs/findings/`](docs/findings/README.md) for each problem found, its cause and its fix, and [`UPDATE-NOTES.md`](UPDATE-NOTES.md) for the chronological log and before/after name tables.

---

## K8s Tutorials

_Available in_: [English](README.md) | [中文 (Chinese)](README-zh.md) | [Português (Portuguese)](README-pt.md) | [Español](README-es.md) | [日本語 (Japanese)](README-ja.md) | [French](README-fr.md)
> **Note:** Such language diversity is brought to you by [contributors](https://github.com/salaboy/platforms-on-k8s/graphs/contributors) from a fantastic cloud-native community.  Huge thanks! 🚀

Each chapter of the book refers to a step-by-step tutorial that you can run to get your hands dirty with some Open Source projects.

- [Chapter 1: (The Rise of) Platforms on Top of Kubernetes](chapter-1/README.md)
- [Chapter 2: Cloud-Native Application Challenges](chapter-2/README.md)
- [Chapter 3: Service Pipelines: Building Cloud-Native applications](chapter-3/README.md)
- [Chapter 4: Environment Pipelines: Deploying Cloud-Native applications](chapter-4/README.md)
- [Chapter 5: Multi-Cloud (App) infrastructure](chapter-5/README.md)
- [Chapter 6: Let's Build a Platform on Top of Kubernetes](chapter-6/README.md)
- [Chapter 7: Platform Capabilities I: Shared Application Concerns](chapter-7/README.md)
- [Chapter 8: Platform Capabilities II: Enabling Teams to Experiment](chapter-8/README.md)
- [Chapter 9: Measure your Platforms](chapter-9/README.md)


Next, you can find information about the application used in the tutorials and mentioned on the book.

## Code

The code for the Conference Application (walking skeleton) and other related artifacts, such as Helm charts and configuration files, can be found inside the [conference-application](conference-application/README.md) directory. All these examples can be built from source, and I encourage you to explore and change these applications.

## Comments / Suggestions / Questions

If you have any comments, suggestions, or questions please [open an issue](https://github.com/salaboy/platforms-on-k8s/issues/new), drop me a comment on my blog [https://www.salaboy.com](https://www.salaboy.com), or contact me via [Twitter @Salaboy](https://twitter.com/salaboy).
