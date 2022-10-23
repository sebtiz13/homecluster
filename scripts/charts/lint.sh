#!/bin/sh
helm dependency build "$1"
helm lint "$1"
