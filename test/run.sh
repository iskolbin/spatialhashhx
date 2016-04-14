#!/bin/bash

pushd ../
haxe SpatialHash.hx -js SpatialHash.js
cat SpatialHash.js | awk 'NR==1 {print "\"use strict\";";} NR>1 {print}' | head -n -1 >> SpatialHash.js
mv SpatialHash.js test/
popd
http-server
