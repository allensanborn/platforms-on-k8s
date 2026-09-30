# Building the Conference Application from Source

You can build the application containers using `ko`

For Kubernetes 1.23 you need Knative 1.8 for Kubernetes 1.24 you need Knative 1.9 or 1.10

If you have [Knative Serving installed](https://knative.dev/docs/install/yaml-install/serving/install-serving-with-yaml/#verify-the-installation) in your cluster you can leverage the `config-knative` directory when running

```shell
ko apply -f config-knative/
```

The services expect Kafka, Redis and PostgreSQL under the names used in [Chapter 8](../../chapter-8/knative/README.md). Bitnami's charts no longer work (their images were removed; see [F001](../../docs/findings/F001-bitnami-images-removed.md)), so install the same infrastructure as Chapter 8 (from the repository root):

```shell
helm upgrade --install cnpg cloudnative-pg --repo https://cloudnative-pg.github.io/charts --version 0.29.1 --namespace cnpg-system --create-namespace --wait
helm upgrade --install strimzi oci://quay.io/strimzi-helm/strimzi-kafka-operator --version 1.2.0 --namespace strimzi --create-namespace --set watchAnyNamespace=true --wait
kubectl apply -f chapter-8/knative/c4p-sql-init.yaml
kubectl apply -f chapter-8/knative/infrastructure/
```

That gives you `kafka-kafka-bootstrap:9092`, `redis:6379` (Secret `redis` / `redis-password`) and `postgresql-rw:5432` (Secret `postgresql-superuser` / `password`), which `config-knative/` points at. For an ingress controller, use ingress-nginx as in [Chapter 2](../../chapter-2/README.md) instead of Bitnami's `nginx-ingress-controller` chart. (Not tested with `ko apply`; the same manifests were tested with the published images in Chapter 8.)
