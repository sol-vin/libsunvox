cd rsrc/example/
shards update
rm -rf bin
rm -rf lib/libsunvox
ln -s ../../../ ./lib/libsunvox 
shards build
./bin/example