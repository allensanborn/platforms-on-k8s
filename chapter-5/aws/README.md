# AWS Cloud Provider

---
_🌍 Available in_: [English](README.md) | [中文 (Chinese)](README-zh.md) | [日本語 (Japanese)](README-ja.md)

> **Note:** Brought to you by the fantastic cloud-native community's [ 🌟 contributors](https://github.com/salaboy/platforms-on-k8s/graphs/contributors)!

---


In this step-by-step tutorial, we will use Crossplane to Provision Redis, PostgreSQL, and Kafka in AWS.

> [!Warning]
> **Updated for Crossplane v2, tested against [Floci](https://github.com/floci-io/floci), not against a real AWS account.** The Compositions use `mode: Pipeline` with `function-patch-and-transform` and provider-upjet-aws's namespaced managed resources (`elasticache.aws.m.upbound.io` ReplicationGroup, `rds.aws.m.upbound.io` Instance, `kafka.aws.m.upbound.io` Cluster, all `v1beta1`). The whole tutorial below, including the Conference application, ran end to end against Floci 2.1.0, a local AWS emulator, on a kind cluster. The same files are meant for a real account, but that was not done. Note that a kind cluster on your laptop cannot reach RDS, ElastiCache or MSK endpoints inside a private AWS VPC, so with a real account the application must run somewhere that can (for example an EKS cluster in that VPC). To follow along without an AWS account, see [Running against Floci](#running-against-floci-no-aws-account).

## Installing Crossplane

To install Crossplane, you need to have a Kubernetes Cluster; you can create one using KinD as we did for you [Chapter 2](../../chapter-2/README.md#creating-a-local-cluster-with-kubernetes-kind). 

Let's install [Crossplane](https://crossplane.io) into its own namespace using Helm: 

```shell
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

helm install crossplane --namespace crossplane-system --create-namespace crossplane-stable/crossplane --version 2.4.2 --wait
```

Install the composition function and the AWS family providers for ElastiCache, RDS, MSK and EC2 (the MSK cluster needs subnets and a security group): 

```shell
kubectl apply -f ../crossplane/functions.yaml
kubectl apply -f providers.yaml
kubectl wait providers --all --for=condition=Healthy --timeout=600s
```

Now we are ready to install our Databases and Message Brokers Crossplane compositions to provision all the components our application needs to work.

## App Infrastructure on demand using Crossplane Compositions

We need to install our Crossplane Compositions for our Key-Value Database (Redis), our SQL Database (PostgreSQL) and our Message Broker(Kafka). 

```shell
kubectl apply -f resources/app-database-resource.yaml -f resources/app-messagebroker-resource.yaml
kubectl wait xrd --all --for=condition=Established --timeout=120s
kubectl apply -f resources/
```

The Crossplane Composition resource (`app-database-redis.yaml`) defines which cloud resources need to be created and how they must be configured together. The Crossplane Composite Resource Definition (XRD) (`app-database-resource.yaml`) defines a simplified interface that enables application development teams to quickly request new databases by creating resources of this type.

Check the [resources/](resources/) directory for the Compositions and the Composite Resource Definitions (XRDs). 

Create a text file containing the AWS account aws_access_key_id and aws_secret_access_key.

```text
[default]
aws_access_key_id = 
aws_secret_access_key = 
```

Create a Kubernetes secret with the AWS credentials. 

```shell
kubectl create secret \
generic aws-secret \
-n crossplane-system \
--from-file=creds=./aws-credentials.txt
```

Create a `ClusterProviderConfig`, which the namespaced managed resources reference: 

```shell
cat <<EOF | kubectl apply -f -
apiVersion: aws.m.upbound.io/v1beta1
kind: ClusterProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-secret
      key: creds
EOF
```

### Let's provision Application Infrastructure

MSK needs one client subnet per broker, each in its own availability zone, and a security group. The Kafka Composition picks them by the label `platform.salaboy.com/msk: "true"`. [`network.yaml`](network.yaml) creates a small VPC with two subnets and a security group carrying that label (on a real account, edit the region and availability zones, or import existing subnets and label them instead).

```shell
kubectl create namespace team-a
kubectl apply -f network.yaml
kubectl wait vpc,subnet,securitygroup -n team-a --all --for=condition=Ready --timeout=600s
```

Now we can request a Key-Value Database, a SQL Database and a Message Broker for our team: 

```shell
kubectl apply -f aws-db-keyvalue.yaml
kubectl apply -f aws-db-sql.yaml
kubectl apply -f aws-messagebroker-kafka.yaml
kubectl wait dbs,mbs -n team-a --all --for=condition=Ready --timeout=1800s
```

On a real account this takes a while (MSK alone can take over 20 minutes). Each managed resource writes its connection details to a Secret in `team-a`:

- `aws-db-sql-postgres-connection`: `address`, `host`, `port`, `username`, `endpoint`, `password`; the generated password is also in `aws-db-sql-postgres-password` (key `password`).
- `aws-db-keyvalue-redis-connection`: `primary_endpoint_address` (or `configuration_endpoint_address`) and `port`.
- The MSK cluster publishes no connection Secret keys; its broker list is in `status.atProvider.bootstrapBrokers`.

Collect the endpoints the application needs. The Redis command prints whichever of the two endpoint fields is set:

```shell
KAFKA=$(kubectl get cluster.kafka.aws.m.upbound.io aws-mb-kafka-kafka -n team-a -o jsonpath='{.status.atProvider.bootstrapBrokers}')
KAFKA=${KAFKA%%,*}
REDIS=$(kubectl get replicationgroup.elasticache.aws.m.upbound.io aws-db-keyvalue-redis -n team-a -o jsonpath='{.status.atProvider.primaryEndpointAddress}{.status.atProvider.configurationEndpointAddress}')
POSTGRES=$(kubectl get secret aws-db-sql-postgres-connection -n team-a -o jsonpath='{.data.address}' | base64 -d)
echo "$KAFKA $REDIS $POSTGRES"
```

Unlike the local Compositions (Strimzi creates the topic, CloudNativePG runs the init SQL), MSK and RDS start empty. MSK doesn't create topics automatically by default, and the c4p-service doesn't create its table. [`init-jobs.yaml`](init-jobs.yaml) runs two Jobs that create the `events-topic` and the `proposals` table:

```shell
kubectl create configmap aws-endpoints -n team-a --from-literal=kafka="$KAFKA"
kubectl apply -f init-jobs.yaml
kubectl wait job --all -n team-a --for=condition=Complete --timeout=600s
```

## Let's deploy our Conference Application

Ok, now that we have our two databases and our message broker running, we need to make sure that our application services connect to these instances. The first thing we need to do is disable the Helm dependencies defined in the Conference Application chart so that when the application gets installed, don't install the databases and the message broker. We can do this by setting the `install.infrastructure` flag to `false`.

[`app-values.yaml`](app-values.yaml) holds the configuration for the services, with three placeholders. Fill them in from the variables above and install the chart:

```shell
sed -e "s|KAFKA_BOOTSTRAP|$KAFKA|" -e "s|REDIS_HOST|$REDIS|" -e "s|POSTGRES_HOST|$POSTGRES|" app-values.yaml > my-app-values.yaml
helm install conference oci://ghcr.io/allensanborn/conference-app --version v1.1.0 -n team-a -f my-app-values.yaml
kubectl wait deploy --all -n team-a --for=condition=Available --timeout=600s
```

The application connects to PostgreSQL on port 5432, Redis on 6379 and Kafka on the port in the bootstrap string; the chart has no settings for other ports.

## Running against Floci (no AWS account)

[Floci](https://github.com/floci-io/floci) emulates the AWS APIs on one port and runs RDS, ElastiCache and MSK as real PostgreSQL, Valkey and Redpanda containers. Tested with Floci 2.1.0. Run it on Docker's `kind` network so the Crossplane providers and the application pods can reach it by name:

```shell
kind create cluster   # creates the `kind` Docker network
docker run -d --name floci --network kind \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e FLOCI_HOSTNAME=floci \
  -e FLOCI_SERVICES_DOCKER_NETWORK=kind \
  -e FLOCI_SERVICES_RDS_PROXY_BASE_PORT=5432 \
  -e FLOCI_SERVICES_RDS_ENDPOINT_HOST=floci \
  floci/floci:2.1.0
```

- `--network kind`: kind routes pod DNS to Docker's embedded DNS, so pods resolve the name `floci` and the names of the Redpanda containers Floci starts (Kafka clients reconnect to the broker's advertised name).
- `FLOCI_HOSTNAME=floci`: the ElastiCache endpoint Floci reports.
- `FLOCI_SERVICES_RDS_PROXY_BASE_PORT=5432` and `FLOCI_SERVICES_RDS_ENDPOINT_HOST=floci`: the first RDS instance is reported as `floci:5432`, the port the c4p-service uses (Floci's default range starts at 7001).

Then follow the tutorial above with one change: instead of creating the credentials Secret and `ClusterProviderConfig`, apply the Floci overlay [`floci/providerconfig.yaml`](floci/providerconfig.yaml), which uses dummy credentials and points the `ec2`, `elasticache`, `kafka`, `rds` and `sts` endpoints at `http://floci:4566`:

```shell
kubectl apply -f floci/providerconfig.yaml
```

On Floci all three resources are Ready within about two minutes. Differences from AWS seen in testing: Floci starts one Redpanda broker however many brokers you ask for, Redpanda creates topics automatically (the topic Job is still harmless), and the Redis endpoint shows up as `configurationEndpointAddress` instead of `primaryEndpointAddress`. The command above handles both.

To clean up, delete the application and the XRs, wait for their managed resources to go, then delete the network and Floci:

```shell
helm uninstall conference -n team-a
kubectl delete -f aws-db-keyvalue.yaml -f aws-db-sql.yaml -f aws-messagebroker-kafka.yaml
kubectl wait --for=delete replicationgroup.elasticache.aws.m.upbound.io,instance.rds.aws.m.upbound.io,cluster.kafka.aws.m.upbound.io -n team-a --all --timeout=1800s
kubectl delete -f network.yaml
docker rm -f floci   # Floci removes the containers it started when their resources are deleted
```
