package main

import (
	"testing"

	"github.com/salaboy/platforms-on-k8s/conference-admin/admin-go/api/types/v1alpha1"
)

func TestWithV1Fields(t *testing.T) {
	env := v1alpha1.Environment{}
	env.Name = "team-a-dev-env"
	env.Spec.Crossplane.CompositionSelector.MatchLabels = map[string]string{"type": "development"}
	env.Status.Conditions = []v1alpha1.Condition{{Type: "Responsive", Status: "True"}, {Type: "Ready", Status: "False"}, {Type: "Synced", Status: "True"}}

	withV1Fields(&env)

	if env.Spec.CompositionSelector.MatchLabels["type"] != "development" {
		t.Errorf("compositionSelector not copied: %+v", env.Spec.CompositionSelector)
	}
	if env.Spec.ResourceRef.Name != "team-a-dev-env" || env.Spec.WriteConnectionSecretToRef.Name != "vc-team-a-dev-env" {
		t.Errorf("refs: %+v %+v", env.Spec.ResourceRef, env.Spec.WriteConnectionSecretToRef)
	}
	c := env.Status.Conditions
	if len(c) != 2 || c[0].Type != "Synced" || c[1].Type != "Ready" || c[1].Status != "False" {
		t.Errorf("conditions: %+v", c)
	}
}
