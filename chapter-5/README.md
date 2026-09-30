# Multi-Cloud (App) Infrastructure

---
_🌍 Available in_: [English](README.md) | [中文 (Chinese)](README-zh.md) | [日本語 (Japanese)](README-ja.md)

> **Note:** Brought to you by the fantastic cloud-native community's [ 🌟 contributors](https://github.com/salaboy/platforms-on-k8s/graphs/contributors)!

---

This step-by-step tutorial use Crossplane to Provision the Redis, PostgreSQL, and Kafka instances for our application services. 

Using Crossplane and Crossplane Compositions, we aim to unify how these components are provisioned, hiding away where these components are for the end users (application teams).

Application teams should be able to request these resources using a declarative approach as with any other Kubernetes Resource. This enables teams to use Environment Pipelines to configure both the application services and the application infrastructure components needed by the application.


## Installing Crossplane

> [!Important]
> This tutorial was updated for **Crossplane v2** (tested with v2.4.2 on kind, September 2026). The book was written against Crossplane v1, and its YAML no longer applies: v2 removed native patch-and-transform Compositions, makes composite resources (XRs) namespaced by default, and moves Crossplane's own fields under `spec.crossplane`. The Bitnami charts the book installed also no longer pull (their versioned images left `docker.io/bitnami` in August 2025). The local Compositions now create a Valkey (Redis-compatible) `Deployment`, a [CloudNativePG](https://cloudnative-pg.io) `Cluster` and [Strimzi](https://strimzi.io) Kafka resources **directly**, which Crossplane v2 can do without the Helm provider. See [`UPDATE-NOTES.md`](../UPDATE-NOTES.md) for every name that changed.

To install Crossplane, you need to have a Kubernetes Cluster; you can create one using KinD as we did for you [Chapter 2](../chapter-2/README.md#creating-a-local-cluster-with-kubernetes-kind). 

Let's install [Crossplane](https://crossplane.io) into its own namespace using Helm: 

```shell
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

helm install crossplane --namespace crossplane-system --create-namespace crossplane-stable/crossplane --version 2.4.2 --wait 
```

The local Compositions use two operators, which must be installed first (the same two that [Chapter 2](../chapter-2/README.md#installing-the-infrastructure-operators) uses):

```shell
helm upgrade --install cnpg cloudnative-pg \
  --repo https://cloudnative-pg.github.io/charts --version 0.29.1 \
  --namespace cnpg-system --create-namespace --wait

helm upgrade --install strimzi oci://quay.io/strimzi-helm/strimzi-kafka-operator \
  --version 1.2.0 --namespace strimzi --create-namespace \
  --set watchAnyNamespace=true --wait
```

In Crossplane v2, Compositions are pipelines of **composition functions**. Our Compositions use `function-patch-and-transform`, which carries the patch-and-transform style the book used. Crossplane also needs permission to manage the operators' resources it composes, which we grant with a `ClusterRole` that aggregates into Crossplane's own role:

```shell
kubectl apply -f crossplane/functions.yaml
kubectl apply -f crossplane/aggregate-to-crossplane.yaml
kubectl wait function/function-patch-and-transform --for=condition=Healthy --timeout=180s
```

> [!Note]
> The Crossplane Helm provider is no longer needed in this chapter. [Chapter 6](../chapter-6/README.md) still uses it, and `crossplane/helm-provider.yaml` installs provider-helm v1.4.0 for that.

Now we are ready to install our Databases and Message Brokers Crossplane compositions to provide all the components our application needs.


## App Infrastructure on demand using Crossplane Compositions

We need to install our Crossplane Composite Resource Definitions (XRDs) for our Key-Value Database (Redis), our SQL Database (PostgreSQL), and our Message Broker (Kafka). 

```shell
kubectl apply -f resources/definitions
kubectl wait xrd --all --for=condition=Established --timeout=120s
```

Now install the corresponding Crossplane Compositions:

```shell
kubectl apply -f resources/compositions
```

The Crossplane Composition resource (`app-database-redis.yaml`) defines which resources need to be created and how they need to be configured together. The Crossplane Composite Resource Definition (XRD) (`app-database-resource.yaml`) defines a simplified interface that enables application development teams to quickly request new databases by creating resources of this type. The XRDs use `scope: Namespaced`, so each team requests databases in its own namespace, and Kubernetes RBAC on that namespace decides who may do so.

Check the [resources/](resources/) directory for the Compositions and the Composite Resource Definitions (XRDs). 


### Let's provision Application Infrastructure

We will work in a namespace for our team, `team-a`. The PostgreSQL Composition runs the `c4p-init-sql` ConfigMap when the database is created, so create it in that namespace first:

```shell
kubectl create namespace team-a
kubectl apply -n team-a -f resources/config
```

We can provision a new Key-Value Database for our team to use by executing the following command: 

```shell
kubectl apply -f my-db-keyvalue.yaml
```

The `my-db-keyvalue.yaml` resource looks like this: 

```yaml
apiVersion: salaboy.com/v1alpha1
kind: Database
metadata:
  name: my-db-keyvalue
  namespace: team-a
spec:
  crossplane:
    compositionSelector:
      matchLabels:
        provider: local
        type: dev
        kind: keyvalue
  parameters:
    size: small
    mockData: false
```

Notice that we are using the labels `provider: local`, `type: dev`, and `kind: keyvalue`, now under `spec.crossplane.compositionSelector`. This allows Crossplane to find the right composition based on the labels. In this case, the Composition created a Valkey `Deployment` and `Service` named `my-db-keyvalue-redis`.

You can check the database status using:

```shell
> kubectl get dbs -n team-a
NAME             SIZE    MOCKDATA   KIND       SYNCED   READY   COMPOSITION                     AGE
my-db-keyvalue   small   false      keyvalue   True     True    keyvalue.db.local.salaboy.com   6s
```

You can follow the same steps to provision a PostgreSQL database by running: 

```shell
kubectl apply -f my-db-sql.yaml
```

You should see now two `dbs`

```shell
> kubectl get dbs -n team-a
NAME             SIZE    MOCKDATA   KIND       SYNCED   READY   COMPOSITION                     AGE
my-db-keyvalue   small   false      keyvalue   True     True    keyvalue.db.local.salaboy.com   2m
my-db-sql        small   false      sql        True     False   sql.db.local.salaboy.com        5s
```

The SQL database becomes `READY` once CloudNativePG reports its `Cluster` healthy, which takes about a minute. CloudNativePG creates a read-write Service `my-db-sql-postgresql-rw` and the Secret `my-db-sql-postgresql-superuser` with the credentials our C4P service uses:

```shell
> kubectl get secret -n team-a
NAME                               TYPE                       DATA   AGE
my-db-sql-postgresql-app           kubernetes.io/basic-auth   11     98s
my-db-sql-postgresql-ca            Opaque                     2      98s
my-db-sql-postgresql-replication   kubernetes.io/tls          2      98s
my-db-sql-postgresql-server        kubernetes.io/tls          2      98s
my-db-sql-postgresql-superuser     kubernetes.io/basic-auth   11     98s
```

We can do the same to provision a new instance of our Kafka Message Broker: 

```shell
kubectl apply -f my-messagebroker-kafka.yaml
```

And then list with (Kafka takes a couple of minutes): 

```shell
> kubectl get mbs -n team-a
NAME          SIZE    KIND    SYNCED   READY   COMPOSITION                  AGE
my-mb-kafka   small   kafka   True     True    kafka.mb.local.salaboy.com   99s
```

The Composition creates a Strimzi `Kafka` named after the `MessageBroker`, a `KafkaNodePool` running one combined controller/broker in KRaft mode, and a `KafkaTopic` for `events-topic`. Kafka doesn't require creating any secret when using a plaintext listener. Its bootstrap address is `my-mb-kafka-kafka-bootstrap:9092`.

You should see these pods:

```shell
> kubectl get pods -n team-a
NAME                                           READY   STATUS    RESTARTS   AGE
my-db-keyvalue-redis-7f95d64c85-k9nlc          1/1     Running   0          2m42s
my-db-sql-postgresql-1                         1/1     Running   0          2m11s
my-mb-kafka-entity-operator-7449946c45-f6rjh   1/1     Running   0          2m1s
my-mb-kafka-my-mb-kafka-dual-role-0            1/1     Running   0          2m40s
```

**Note**: deleting a `Database` or `MessageBroker` now also deletes its PersistentVolumeClaims: CloudNativePG owns its PVCs, and the Kafka Composition sets Strimzi's `deleteClaim: true`.

You can now create as many database or message broker instances as your cluster resources can handle! 

## Let's deploy our Conference Application

Ok, now that we have our two databases and our message broker running, we need to make sure that our application services connect to these instances. The first thing that we need to do is to disable the infrastructure bundled in the Conference Application chart so that when the application gets installed, it doesn't install the databases and the message broker. We can do this by setting the `install.infrastructure` flag to `false`.

For that, we will use the `app-values.yaml` file containing the configurations for the services to connect to our newly created databases. The book's chart `oci://registry-1.docker.io/salaboy/conference-app:v1.0.0` still embeds the Bitnami subcharts, so use this fork's `v1.1.0` (from the `chapter-5` directory):

```shell
helm install conference oci://ghcr.io/allensanborn/conference-app --version v1.2.0 -n team-a -f app-values.yaml
```

(Alternative, from the repository root: `helm dependency update conference-application/helm/conference-app && helm install conference conference-application/helm/conference-app -n team-a -f chapter-5/app-values.yaml`.)

The `app-values.yaml` content looks like this: 
```yaml
install:
  infrastructure: false
frontend:
  kafka:
    url: my-mb-kafka-kafka-bootstrap.team-a.svc.cluster.local
agenda:
  kafka:
    url: my-mb-kafka-kafka-bootstrap.team-a.svc.cluster.local
  redis:
    host: my-db-keyvalue-redis.team-a.svc.cluster.local
    # the local keyvalue Database is a dev Valkey without auth, so no secretName
c4p:
  kafka:
    url: my-mb-kafka-kafka-bootstrap.team-a.svc.cluster.local
  postgresql:
    host: my-db-sql-postgresql-rw.team-a.svc.cluster.local
    secretName: my-db-sql-postgresql-superuser
    secretKey: password
notifications:
  kafka:
    url: my-mb-kafka-kafka-bootstrap.team-a.svc.cluster.local
```

Notice that the `app-values.yaml` file relies on the names that we specified for our databases (`my-db-keyvalue` and `my-db-sql`) and our message brokers (`my-mb-kafka`) in the example files. If you request other databases and message brokers with different names you will need to adapt this file with the new names.

Once the application pods start you should have access to the application by pointing your browser to [http://localhost](http://localhost) if you created the cluster with the Chapter 2 ingress setup, or run `kubectl port-forward svc/frontend -n team-a 8080:80` and use [http://localhost:8080](http://localhost:8080). 
If you made it this far, you can now provision multi-cloud infrastructure using Crossplane Compositions. Check the [AWS Crossplane Compositions Tutorial](aws/) which was contributed by [@asarenkansah](https://github.com/asarenkansah). By separating the application infrastructure provision from the application code you not only enable cross-cloud provider portability but also enable teams to connect the application's services with infrastructure that can be managed by the platform team.


## Clean up

If you want to get rid of the KinD Cluster created for this tutorial, you can run:

```shell
kind delete clusters dev
```


## Next Steps

If you have access to a Cloud Provider such as Google Cloud Platform, Microsoft Azure, or Amazon AWS, I strongly recommend you check the **Crossplane Providers** for these platforms. Installing these providers and provisioning Cloud Resources, instead of composing local operators, will give you real-life experience on how these tools work. 

As mentioned in Chapter 5, how would you deal with services that need infrastructure components that are not offered as managed services? In the case of Google Cloud Platform, they don't offer a Managed Kafka Service that you can provision. Would you install Kafka using Helm Charts or VMs or would you switch Kafka for a managed service such as Google PubSub? Would you maintain two versions of the same service? 


## Sum up and Contribute

In this tutorial, we have managed to separate the provisioning for the application infrastructure from the application deployment. This enables different teams to request resources on-demand (using Crossplane compositions) and application services that can evolve independently. 

Using Helm Chart dependencies for development purposes and quickly getting a fully functional instance of the application up and running is great. For more sensitive environments, you might want to follow an approach like the one shown here, where you have multiple ways to connect your application with the components required by each service. 

Do you want to improve this tutorial? Create an issue, drop me a message on [Twitter](https://twitter.com/salaboy), or send a Pull Request.
