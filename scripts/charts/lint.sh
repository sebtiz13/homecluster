#!/bin/sh
helm dependency build --skip-refresh "$1"
helm lint "$1"
