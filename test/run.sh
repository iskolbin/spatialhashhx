#!/bin/bash

pushd ../
haxe SpatialHash.hx -js SpatialHash.js
#cat SpatialHash.js | sed '$d' | awk 'NR==1 {print "\"use strict\";"} NR>1 {print;}' > test/SpatialHash.js
cat SpatialHash.js | sed 's/(function (console) { "use strict";/"use strict";/g' | sed 's/})(typeof console != "undefined" ? console : {log:function(){}});//g' > test/SpatialHash.js
popd
http-server
