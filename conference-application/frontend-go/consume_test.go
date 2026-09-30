package main

import (
	"context"
	"errors"
	"io"
	"testing"

	"github.com/segmentio/kafka-go"
)

type fakeReader struct{ results []error }

func (f *fakeReader) ReadMessage(ctx context.Context) (kafka.Message, error) {
	err := f.results[0]
	f.results = f.results[1:]
	if err != nil {
		return kafka.Message{}, err
	}
	return kafka.Message{Value: []byte(`{"id":"e1","type":"new-proposal"}`)}, nil
}

func TestConsumeFromKafkaRetriesTransientErrors(t *testing.T) {
	retryDelay = 0
	events = nil
	consumeFromKafka(&fakeReader{results: []error{errors.New("[16] Not Coordinator For Group"), nil, io.EOF}})
	if len(events) != 1 || events[0].Id != "e1" {
		t.Fatalf("expected one event after a transient error, got %+v", events)
	}
}
