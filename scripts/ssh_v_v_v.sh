#!/bin/bash

echo "running ssh -v -v -v $@" >&2

ssh -v -v -v "${@}"
