#!/bin/sh
CHART=$1

helm dependency build "$CHART"
helm cm-push "$CHART" my-repo
