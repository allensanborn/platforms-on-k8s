# Chapter 9 :: Measuring your Platforms

---
_🌍 Available in_: [English](README.md) | [中文 (Chinese)](README-zh.md) | [日本語 (Japanese)](README-ja.md) | [Spanish](README-es.md)

> **Note:** Brought to you by the fantastic cloud-native community's [ 🌟 contributors](https://github.com/salaboy/platforms-on-k8s/graphs/contributors)!

---

This chapter cover two different tutorials on how to use DORA metrics to measure your platform initiative performances. 

- [DORA metrics and CloudEvents](dora-cloudevents/README.md)
- [Deployment frequency with Argo CD (formerly Keptn Lifecycle Toolkit)](keptn/README.md)

## Sum up

The tutorials covered in this chapter aim to show two completely different, but complementary approaches that we can use to observe and monitor our applications. While the first tutorial focuses on CloudEvents and CDEvents to show how platform teams can tap into different event sources to calculate DORA metrics, the second tutorial uses Argo CD and Argo Rollouts to get deployment frequency, rollout traces, post-deployment tasks and release gates out of the box. The book uses the Keptn Lifecycle Toolkit here, which the CNCF archived in 2025. 

Platform teams should evaluate tools like the ones presented here, not only to calculate metrics, but also to justify their platform investments. If platform decisions and initiatives improve team's deployment frequency, lead time for changes while at the same time reduce the time to recovery from failures, you are building the right platform. If you notice that teams are not deploying as often, changes are taking longer to be infront of customers you might need to revaluate your choices. 


## Clean up

If you want to get rid of the KinD Cluster created for this tutorial, you can run:

```shell
kind delete clusters dev
```

