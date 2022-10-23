#!/bin/sh
helm dependency build "$1"
helm cm-push "$1" my-repo
