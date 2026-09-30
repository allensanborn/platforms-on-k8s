package v1alpha1

//go:generate controller-gen object paths=$GOFILE

import metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

type Frontend struct {
	Debug bool `json:"debug"`
}

type Parameters struct {
	InstallInfra bool     `json:"installInfra"`
	Frontend     Frontend `json:"frontend"`
}

type CompositionSelector struct {
	MatchLabels map[string]string `json:"matchLabels"`
}

type WriteConnectionSecretToRef struct {
	Name string `json:"name"`
}

type Condition struct {
	Status string `json:"status"`
	Type   string `json:"type"`
	Reason string `json:"reason"`
}

type EnvironmentStatus struct {
	Conditions []Condition `json:"conditions"`
}

type ResourceRef struct {
	Name string `json:"name,omitempty"`
}

// Crossplane holds the fields Crossplane v2 keeps under spec.crossplane.
type Crossplane struct {
	CompositionSelector CompositionSelector `json:"compositionSelector"`
}

// EnvironmentSpec: Crossplane v2 namespaced Environment. CompositionSelector,
// WriteConnectionSecretToRef and ResourceRef are the v1 (claim) fields; the API
// server prunes them on write, and the admin API fills them in on read for the UI.
type EnvironmentSpec struct {
	Crossplane                 Crossplane                 `json:"crossplane"`
	WriteConnectionSecretToRef WriteConnectionSecretToRef `json:"writeConnectionSecretToRef,omitempty"`
	Parameters                 Parameters                 `json:"parameters"`
	CompositionSelector        CompositionSelector        `json:"compositionSelector,omitempty"`
	ResourceRef                *ResourceRef               `json:"resourceRef,omitempty"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
type Environment struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   EnvironmentSpec   `json:"spec"`
	Status EnvironmentStatus `json:"status"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
type EnvironmentList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`

	Items []Environment `json:"items"`
}
