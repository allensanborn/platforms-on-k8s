# Chapter 2 :: Cloud-Native Application Challenges

---
_🌍 Available in_: [English](README.md) | [中文 (Chinese)](README-zh.md) | [Português (Portuguese)](README-pt.md)  | [日本語 (Japanese)](README-ja.md) | [Español](README-es.md) | [Français](README-fr.md)

> **Note:** Brought to you by the fantastic cloud-native community's [ 🌟 contributors](https://github.com/salaboy/platforms-on-k8s/graphs/contributors)!

In this short tutorial, we will be installing the `Conference Application` using Helm into a local KinD Kubernetes Cluster. 

> [!NOTE]
> Helm Charts can be published to Helm Chart repositories or also, since Helm 3.7, as OCI containers to container registries. 

## Creating a local cluster with Kubernetes KinD

> [!Important]
> Make sure you have the pre-requisites for all the tutorials. You can find them [here](../chapter-1/README.md#pre-requisites-for-the-tutorials).

Use the command below to create a KinD Cluster with three worker nodes and 1 Control Plane.

```shell
cat <<EOF | kind create cluster --name dev --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
- role: worker
EOF

```

![3 worker nodes](imgs/cluster-topology.png)

### Loading some container images before installing the application and other components

The `kind-load.sh` script prefetches, in other words, pulls and loads container images that we will use for our application to our KinD Cluster. 

The idea here is to optimize the process for our Cluster, so that when we install the application, we won't have to wait for 10+ minutes while all needed container images are being fetched. With all images already preloaded into our KinD cluster, the application should start in around 1 minute, which is the time needed for PostgreSQL, Redis and Kafka to bootstrap. 

Now, let's fetch the required images into our KinD cluster.

> [!Important]
> By running the script mentioned in next step, you will fetch all the required images and then load them into every node of your KinD cluster. If you are running the examples on a Cloud Provider, this might not be worth it as Cloud Providers with Gigabyte connections to container registries might fetch these images in a matter of seconds.

In your terminal, access the`chapter-2` directory, and from there, run the script: 

```shell
./kind-load.sh
```

> [!Note]
> If you are running Docker Desktop on MacOS and have set a smaller size for the virtual disk, you may encounter the following error:
>
> ```shell
> $ ./kind-load.sh
> ...
> Command Output: Error response from daemon: write /var/lib/docker/...
> /layer.tar: no space left on device
> ```
>
> You can modify the value of the Virtual Disk limit in the ``Settings -> Resources`` menu.
>   ![MacOS Docker Desktop virtual disk limits](imgs/macos-docker-desktop-virtual-disk-setting.png)


### Installing NGINX Ingress Controller

We need the NGINX Ingress Controller to route traffic from our laptop to the services running inside the cluster. NGINX Ingress Controller acts as a router that is running inside the cluster but is also exposed to the outside world. 

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

Newer versions of this manifest no longer pin the controller to the node labelled `ingress-ready=true`. On a cluster with worker nodes the controller can land on a worker, and then `http://localhost` answers with "connection reset". Pin it to the control-plane node, which is the one with the port mappings:

```shell
kubectl patch deploy -n ingress-nginx ingress-nginx-controller \
  -p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"}}}}}'
```

Check that the pods inside the `ingress-nginx` are started correctly before proceeding: 
```shell
> kubectl get pods -n ingress-nginx
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-cflcl        0/1     Completed   0          62s
ingress-nginx-admission-patch-sb64q         0/1     Completed   0          62s
ingress-nginx-controller-5bb6b499dc-7chfm   0/1     Running     0          62s
```

This should allow you to route traffic from `http://localhost` to services inside the cluster. Notice that for KinD to work in this way, we provided extra parameters and labels for the control plane node when we created the cluster:
```yaml
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true" #This allow the ingress controller to be installed in the control plane node
  extraPortMappings:
  - containerPort: 80 # This allows us to bind port 80 in local host to the ingress controller, so it can route traffic to services running inside the cluster.
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
```

Once we have our cluster and our Ingress Controller installed and configured, we can move ahead to install our application.


## Installing the infrastructure operators

> [!Important]
> The book's version of the chart used Bitnami's Redis, PostgreSQL and Kafka charts. Bitnami stopped publishing its versioned images to `docker.io/bitnami` in August 2025, so those pods now fail with `ImagePullBackOff`. The chart in this repository now uses the official [Valkey](https://valkey.io) chart (a Redis-compatible fork), a [CloudNativePG](https://cloudnative-pg.io) `Cluster` for PostgreSQL and a [Strimzi](https://strimzi.io) `Kafka` for Kafka. The last two are Kubernetes operators, which must be installed once per cluster before the application:

```shell
helm upgrade --install cnpg cloudnative-pg \
  --repo https://cloudnative-pg.github.io/charts --version 0.29.1 \
  --namespace cnpg-system --create-namespace --wait

helm upgrade --install strimzi oci://quay.io/strimzi-helm/strimzi-kafka-operator \
  --version 1.2.0 --namespace strimzi --create-namespace \
  --set watchAnyNamespace=true --wait
```

## Installing the Conference Application

From Helm 3.7+, we can use OCI images to publish, download, and install Helm Charts. The book's chart, `oci://docker.io/salaboy/conference-app:v1.0.0`, still depends on the Bitnami images, so this fork publishes the updated chart, and images rebuilt from this repository, to GitHub Container Registry as `v1.2.0`:

```shell
helm install conference oci://ghcr.io/allensanborn/conference-app --version v1.2.0
```

(Alternative: install from the repository checkout with `helm dependency update conference-application/helm/conference-app && helm install conference conference-application/helm/conference-app`.)

You can also run the following command to see the details of the chart: 

```shell
helm show all oci://ghcr.io/allensanborn/conference-app --version v1.2.0
```

Check that all the application pods are up and running. 

> [!Note]
> Notice that if your internet connection is slow, it might take a while for the application to start. Since the application's services depend on some infrastructure components (Redis, Kafka, PostgreSQL), these components need to start and be ready for the services to connect. 
> 
> Kafka is the slowest to start: the Strimzi operator first starts a combined controller/broker pod, then an entity operator that creates the `events-topic` topic. On a laptop this takes about 5 minutes.

Eventually, you should see something like this. It can take a few minutes: 

```shell
kubectl get pods
NAME                                                          READY   STATUS    RESTARTS   AGE
conference-agenda-service-deployment-54c89fb8cd-dgtmv         1/1     Running   0          52s
conference-c4p-service-deployment-694f967459-zlg88            1/1     Running   0          52s
conference-conference-dual-role-0                             1/1     Running   0          50s
conference-entity-operator-5bf54f6b6f-n25bf                   1/1     Running   0          13s
conference-frontend-deployment-7f48d6cdcc-lgzfm               1/1     Running   0          52s
conference-notifications-service-deployment-95dfd8c6b-r922h   1/1     Running   0          52s
conference-postgresql-1                                       1/1     Running   0          16s
conference-redis-5895ff567d-5ljq8                             1/1     Running   0          52s
```

Each service has a `wait-for-dependencies` init container that waits until Kafka (and Redis or PostgreSQL) accept connections, so the services start only once their infrastructure is up instead of crash-looping. You can also wait for the infrastructure explicitly:

```shell
kubectl wait --for=condition=Ready cluster.postgresql.cnpg.io/conference-postgresql --timeout=300s
kubectl wait --for=condition=Ready kafka/conference --timeout=600s
```

> [!Note]
> **Troubleshooting on kind:** if a request fails with HTTP 500 and the service logs show `dial tcp …:9092: i/o timeout` although `kubectl get kafka` says `Ready`, kind's network-policy enforcement is blocking the broker ([F007](../docs/findings/F007-kafka-bootstrap-timeout-on-kind.md)). Run `kubectl delete networkpolicy conference-network-policy-kafka` and wait about 2 minutes, or install Strimzi with `--set generateNetworkPolicy=false` on local clusters.

Now you can point your browser to [http://localhost](http://localhost) to see the application. 

![conference app](imgs/conference-app-homepage.png)

------
## [Important] Clean up - _!!! Must READ!!_

Because the Conference Application is installing PostgreSQL, Redis, and Kafka, if you want to remove and install the application again (which we will do as we move through the guides), you need to make sure to delete the associated PersistenceVolumeClaims (PVCs). 

These PVCs are the volumes used to store the data from the databases and Kafka. Failing to delete these PVCs in between installations will cause the services to use old credentials to connect to the new provisioned databases. 

You can delete all PVCs by listing them with:

```shell
kubectl get pvc
```

You should see:

```shell
NAME                                       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
conference-postgresql-1                    Bound    pvc-e97f17c6-59d3-4d3e-a433-78dab19ccac5   1Gi        RWO            standard       14m
conference-redis                           Bound    pvc-30a8d528-1d05-4687-9494-5ccde4c06de7   1Gi        RWO            standard       14m
data-0-conference-conference-dual-role-0   Bound    pvc-5c8770ba-95d8-4039-9c84-eed6becc7135   1Gi        RWO            standard       14m
```

The CloudNativePG and Strimzi operators delete their own PVCs when the `Cluster` and `Kafka` resources are deleted with the release (the chart sets Strimzi's `deleteClaim: true`). The Valkey PVC is kept by `helm uninstall`; delete it with: 
```shell
kubectl delete pvc conference-redis
```

The name of the PVCs will change based on the Helm Release name that you used when installing the chart.

Finally, if you want to get rid of the KinD Cluster entirely, you can run:

```shell
kind delete clusters dev
```

-------
## Next Steps

I strongly recommend you get your hands dirty with a real Kubernetes Cluster hosted in a Cloud Provider. You can try most Cloud Providers, as they offer a free trial where you can create Kubernetes Clusters and run all these examples [check this repository for more information](https://github.com/learnk8s/free-kubernetes). 

If you can create a Cluster in a Cloud provider and get the application up and running, you will gain real-life experience on all the topics covered in Chapter 2.

## Sum up and Contribute

In this short tutorial, we have managed to install the **Conference Application** walking skeleton. We will use this application as an example throughout the rest of the chapters. Make sure that this application works for you as it covers the basics of using and interacting with a Kubernetes Cluster.

Do you want to improve this tutorial? Create an [issue](https://github.com/salaboy/platforms-on-k8s/issues/new), message me on [Twitter](https://twitter.com/salaboy), or send a [Pull Request](https://github.com/salaboy/platforms-on-k8s/compare).
