#!/bin/sh
# helm dependency build --skip-refresh "$1" #? its run on lint
helm cm-push "$1" my-repo
