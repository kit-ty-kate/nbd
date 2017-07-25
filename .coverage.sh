#!/bin/sh

set -ex

COVERAGE_DIR=.coverage
rm -rf $COVERAGE_DIR
mkdir -p $COVERAGE_DIR
pushd $COVERAGE_DIR
if [ -z "$KEEP" ]; then trap "popd; rm -rf $COVERAGE_DIR" EXIT; fi

$(which cp) -r ../* .

opam pin add bisect_ppx --dev-repo -y
opam install ocveralls -y

export COVERAGE=1
jbuilder runtest

outs=$(find . | grep bisect.*.out)
bisect-ppx-report -I $(dirname $outs[1]) -text report $outs
bisect-ppx-report -I $(dirname $outs[1]) -summary-only -text summary $outs
if [ -n "$HTML" ]; then bisect-ppx-report -I $(dirname $outs[1]) -html ../html-report $outs; fi

if [ -n "$TRAVIS" ]; then
  echo "\$TRAVIS set; running ocveralls and sending to coveralls.io..."
  ocveralls --prefix $(dirname $outs[1]) $outs --send
else
  echo "\$TRAVIS not set; displaying results of bisect-report..."
  cat report
  cat summary
fi
