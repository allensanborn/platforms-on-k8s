# Chapter 6 :: Let's build a Platform on top of Kubernetes

---
_🌍 Available in_: [English](README.md) | [中文 (Chinese)](README-zh.md) | [日本語 (Japanese)](README-ja.md)

> **Note:** Brought to you by the fantastic cloud-native community's [ 🌟 contributors](https://github.com/salaboy/platforms-on-k8s/graphs/contributors)!

---


In this step-by-step tutorial, we will create our platform's APIs by reusing the Kubernetes APIs' power. The first use case where the platform can assist the development teams is by creating new development environments and providing a self-service approach. 

To build this example, we will use Crossplane and `vcluster`, two Open Source projects hosted in the Cloud-Native Computing Foundation. 

## Installation 

To install Crossplane, you need to have a Kubernetes Cluster; you can create one using KinD as we did for you [Chapter 2](../chapter-2/README.md#creating-a-local-cluster-with-kubernetes-kind). 

Then you can install Crossplane (v2) and `function-patch-and-transform` in your cluster as we did in [Chapter 5](../chapter-5/README.md#installing-crossplane). This chapter also needs the Crossplane Helm provider (v1.4.0) and a cluster-wide `ClusterProviderConfig` named `default` that lets it install charts into the host cluster:

```shell
kubectl apply -f ../chapter-5/crossplane/helm-provider.yaml
kubectl wait provider/provider-helm --for=condition=Healthy --timeout=300s
kubectl apply -f crossplane/helm-provider-config.yaml
```

> [!Important]
> Updated for **Crossplane v2** and **vcluster 0.37.2** (tested on kind, September 2026). `Environment` is now a **namespaced** composite resource with no claim: a team creates it in its own namespace, and the vcluster runs there. The Composition is a function pipeline, and it uses provider-helm's namespaced `helm.m.crossplane.io` Releases and ProviderConfigs. The Conference chart's infrastructure is now operator-based (see [Chapter 2](../chapter-2/README.md#installing-the-infrastructure-operators)), so the Composition installs the CloudNativePG and Strimzi operators *inside* each vcluster before the application. The application chart is this fork's `oci://ghcr.io/allensanborn/conference-app:v1.1.0`, because the book's `oci://docker.io/salaboy/conference-app:v1.0.0` still uses Bitnami images. A copy of the same chart is in [`charts/`](charts/); to use it instead, replace the Composition's `chart.repository`/`chart.version` with `chart.url: https://raw.githubusercontent.com/allensanborn/platforms-on-k8s/crossplane-v2-and-bitnami-replacements/chapter-6/charts/conference-app-v1.1.0.tgz`.

We will use [`vcluster`](https://www.vcluster.com/) in this tutorial, but there is no need to install anything in our cluster for vcluster to work. We need the `vcluster` CLI to connect to our `vcluster`s you can install it by following the instructions on the official site: [https://www.vcluster.com/docs/getting-started/setup](https://www.vcluster.com/docs/getting-started/setup)


## Defining our Environment API

An environment represents a Kubernetes cluster where the Conference Application will be installed for development. The idea is to provide teams with self-service environments for them to do their work. 

For this tutorial, we will define an Environment API and a Crossplane Composition that uses the Helm Provider to create a new instance of `vcluster`. 

Check the Crossplane Composite Resource Definition (XRD) for our [Environments here](resources/env-resource-definition.yaml) and the Crossplane [Composition here](resources/composition-devenv.yaml). This resource configures the provisioning of a new `vcluster` using the Crossplane Helm Provider, [check this configuration here](https://github.com/salaboy/platforms-on-k8s/blob/main/chapter-6/resources/composition-devenv.yaml#L24). When a new `vcluster` is created then the composition install our Conference Application into it, once again using the Crossplane Helm Provider, but this time configured [pointing to the just created `vcluster` APIs](https://github.com/salaboy/platforms-on-k8s/blob/main/chapter-6/resources/composition-devenv.yaml#L87), you can [check this here](https://github.com/salaboy/platforms-on-k8s/blob/main/chapter-6/resources/composition-devenv.yaml#L117).

Let's install both XRD by running: 

```shell
kubectl apply -f resources/definitions
```

Now that the XRD is defined, let's install the Composition by running:

```shell
kubectl apply -f resources/compositions
```

You should see: 

```shell
composition.apiextensions.crossplane.io/dev.env.salaboy.com created
compositeresourcedefinition.apiextensions.crossplane.io/environments.salaboy.com created
```

With the Environment resource and the Crossplane Composition using `vcluster` our teams can now request their Environments on demand. 


## Requesting a new Environment

To request a new Environment, teams can create new environment resources like this one: 

```yaml
apiVersion: salaboy.com/v1alpha1
kind: Environment
metadata:
  name: team-a-dev-env
  namespace: team-a
spec:
  crossplane:
    compositionSelector:
      matchLabels:
        type: development
  parameters:
    installInfra: true
    frontend:
      debug: true
```

Once sent to the cluster, the Crossplane Composition will kick in and create a new `vcluster` with an instance of the Conference Application inside. 

```shell
kubectl create namespace team-a
kubectl apply -f team-a-dev-env.yaml
```
You should see: 

```shell
environment.salaboy.com/team-a-dev-env created
```

You can always check the state of your Environments by running: 

```shell
> kubectl get env -n team-a
NAME             CONNECT-TO       TYPE          INFRA   DEBUG   SYNCED   READY   COMPOSITION           AGE
team-a-dev-env   team-a-dev-env   development   true    true    True     True    dev.env.salaboy.com   3m41s
```

The Composition creates five managed resources in the `team-a` namespace: the vcluster Release, a `ProviderConfig` pointing at the new vcluster, and three Releases installed *inside* the vcluster (the two operators and the application):

```shell
> kubectl get releases.helm.m.crossplane.io -n team-a
NAME                        CHART                    VERSION   SYNCED   READY   STATE      REVISION   DESCRIPTION        AGE
team-a-dev-env              vcluster                 0.37.2    True     True    deployed   1          Install complete   3m40s
team-a-dev-env-cnpg         cloudnative-pg           0.29.1    True     True    deployed   1          Install complete   3m40s
team-a-dev-env-conference   conference-app           v1.1.0    True     True    deployed   1          Install complete   3m40s
team-a-dev-env-strimzi      strimzi-kafka-operator   1.2.0     True     True    deployed   1          Install complete   3m39s
```

Creation is eventually consistent, so expect warning events on the inner Releases for the first minutes: the vcluster's kubeconfig Secret (`vc-team-a-dev-env`) doesn't exist yet, then the CloudNativePG and Strimzi CRDs or webhooks aren't ready when the application chart is first installed. provider-helm retries (the application Release sets `rollbackLimit: 3` so a failed first install is retried). `READY` on the Environment means the Helm releases are deployed; the application pods need a few more minutes for Kafka to start.

Then we can connect to the provisioned environment by running (use the CONNECT-TO column for the vcluster name): 
```shell
vcluster connect team-a-dev-env -n team-a
```

Once you are connected to the `vcluster` you are in a different Kubernetes Cluster, so if you list all the available namespaces, you should see `cnpg-system` and `strimzi` (the operators) but not `crossplane-system`. If you list all the pods in the `default` namespace, you should see all the application pods running: 

```shell
NAME                                                           READY   STATUS    RESTARTS      AGE
conference-agenda-service-deployment-69d8ffc5f7-fkwjs          1/1     Running   3 (50s ago)   72s
conference-c4p-service-deployment-689ccc8778-h8p44             1/1     Running   3 (53s ago)   72s
conference-conference-dual-role-0                              1/1     Running   0             65s
conference-entity-operator-76699f9d75-txttp                    1/1     Running   0             23s
conference-frontend-deployment-689884567b-s98zx                1/1     Running   3 (51s ago)   72s
conference-notifications-service-deployment-568c97bb54-prltv   1/1     Running   3 (49s ago)   72s
conference-postgresql-1                                        1/1     Running   0             49s
conference-redis-867cb66d5f-pg98p                              1/1     Running   0             72s
```

You can also do port-forwarding to this cluster, to access the application using:
```shell
kubectl port-forward svc/frontend 8080:80
```
Now your application is available at [http://localhost:8080](http://localhost:8080). Because the Environment set `frontend.debug: true`, `curl http://localhost:8080/api/features/` returns `"DebugEnabled":"true"`.

How the Composition reaches the vcluster: vcluster writes a kubeconfig to the Secret `vc-<name>` (key `config`) in the team namespace, with the server set by the chart value `exportKubeConfig.server`. The Composition sets it to `https://<name>.<namespace>:443`. Don't add `.svc`: vcluster 0.37's serving certificate lists `<name>` and `<name>.<namespace>` but not `<name>.<namespace>.svc`, and provider-helm then fails with `x509: certificate is valid for ..., not team-a-dev-env.team-a.svc`. No `insecure` flag or extra SANs are needed with the shorter name.

You can exit the `vcluster` context by typing `exit` in the terminal.


## Simplifying our platform surface

We can go one step further to simplify the interaction with the platform APIs, preventing teams from connecting to the Platform Cluster and removing the need for having access to the Kubernetes APIs. 

In this short section, we deploy an Admin User Interface that allows teams to request new environments using a website, or a set of simplified REST APIs. 

Before installing the Admin User Interface, you need to make sure that you are not inside a `vcluster` session. (You can exit the `vcluster` context by typing `exit` in the terminal). Check that you have the `crossplane-system` namespaces in the current cluster where you are connected. 

> [!Warning]
> **Not updated for Crossplane v2 (untested).** The Admin application (`conference-admin/admin-go`) still writes the v1 shape of `Environment`: `spec.compositionSelector` at the top level and `spec.writeConnectionSecretToRef`, with no namespace handling for a namespaced XR. Making it work needs Go changes (`api/types/v1alpha1/environment.go` and the client calls) and a rebuilt image, which this update doesn't include.

You can install this Admin User Interface using Helm:

```shell
helm install admin oci://docker.io/salaboy/conference-admin --version v1.0.0
```

Once installed you can port-forward to the Admin UI by running: 

```shell
kubectl port-forward svc/admin 8081:80
```

Now you can create and check your environments using a simple interface at [http://localhost:8081](http://localhost:8081). If you wait for the environment to be ready, you will get the `vcluster` command to use to connect to the environment.

![imgs/admin-ui.png](imgs/admin-ui.png)

By using this simple interface, development teams will not need to access the Kubernetes APIs from the cluster which has all the platform tools (Crossplane and Argo CD for example) directly.

Besides the User interface, the Platform Admin application offers you a simplified set of REST endpoints where you have full flexibility to define how the resources look like instead of following the Kubernetes Resource Model. For example, instead of having a Kubernetes Resource with all the metadata needed by the Kubernetes API, we can use the following JSON payload to create a new Environment: 

```json
{
    "name": "team-curl-dev-env",
    "parameters":{
        "type": "development",
        "installInfra": true,
        "frontend":{
            "debug": true
        }
    }
}
```

You can create this environment by running:

```shell
curl -X POST -H "Content-Type: application/json" -d @team-a-dev-env-simple.json http://localhost:8081/api/environments/
```

Then list all the environments with: 
```shell
curl localhost:8081/api/environments/
```

Or delete one environment running: 

```shell
curl -X DELETE http://localhost:8081/api/environments/team-curl-dev-env
```

This application serves as a facade between Kubernetes and the outside world. Depending on your organization's needs, you might want to have these abstractions (APIs) early on, so the platform team can pivot on their tooling and workflow decisions under the covers.


## Clean up

Deleting an Environment deletes its vcluster, and everything inside it with it (`kubectl delete -f team-a-dev-env.yaml`). The Releases installed inside the vcluster use `managementPolicies` without `Delete`, because once the vcluster is gone they could never reach it to uninstall and would hang on their finalizers. vcluster's own PersistentVolumeClaim (`data-team-a-dev-env-0`) is kept by Helm; delete it before re-creating an Environment with the same name.

If you want to get rid of the KinD Cluster created for these tutorials, you can run:

```shell
kind delete clusters dev
```


## Next Steps

Can you extend the Admin User Interface to create Databases and Message Brokers like we did in Chapter 5? What would it take? Understanding where the changes need to be made will give you hands-on experience in developing components that interact with the Kubernetes APIs and provide simplified interfaces for consumers.

Can you create your own compositions to use Real Clusters instead of `vcluster`? For which kind of scenario would you use a real Cluster and when a `vcluster`?

What extra steps would you need to do to run this in a real Kubernetes Cluster instead of running this on Kubernetes KinD? 



## Sum up and Contribute

In this tutorial, we have built a new Platform API reusing the Kubernetes Resource model to provision on-demand development environments. On top of that with the Platform Admin application we have created a simplified layer to expose the same capabilities without pushing teams to learn about how Kubernetes works or the underlying details, projects, and technologies that we have used to build our Platform. 

By relying on contracts (for this example the Environment resource definition), the platform team has the flexibility to change the mechanisms used to provision environments depending on their requirements and available tools. 

Do you want to improve this tutorial? Create an issue, drop me a message on [Twitter](https://twitter.com/salaboy), or send a Pull Request.
