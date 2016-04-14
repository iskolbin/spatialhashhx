#!/bin/bash

pushd ../
haxe SpatialHash.hx -js SpatialHash.js
cat SpatialHash.js | sed '$d' | awk 'NR==1 {print "\"use strict\";"} NR>2 {print;}' > test/SpatialHash.js
popd
http-server
