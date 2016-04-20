#!/bin/bash

### coqproject.sh
### Creates a _CoqProject file, including external dependencies.

### See README.md for a description.

## Implementation

if [ -z ${DIRS+x} ]; then DIRS=(.); fi

COQPROJECT_TMP=_CoqProject.tmp

rm -f $COQPROJECT_TMP
touch $COQPROJECT_TMP
for dep in ${DEPS[@]}; do
    path_var="$dep"_PATH
    path=${!path_var:="../$dep"}
    if [ ! -d "$path" ]; then
        echo "$dep not found at $path."
        exit 1
    fi

    pushd "$path" > /dev/null
    path=$(pwd)
    popd > /dev/null
    echo "$dep found at $path"
    LINE="-Q $path $dep"
    echo $LINE >> $COQPROJECT_TMP
done

COQTOP="coqtop $(cat $COQPROJECT_TMP)"
function check_canary(){
    echo "Require Import $@." | $COQTOP 2>&1 | grep -i error 1> /dev/null 2>&1 
}
i=0
len="${#CANARIES[@]}"
while [ $i -lt $len ]; do
    if check_canary ${CANARIES[$i]}; then
        echo "Error: ${CANARIES[$((i + 1))]}"
        exit 1
    fi
    let "i+=2"
done

for dir in ${DIRS[@]}; do
    namespace_var=NAMESPACE_"$dir"
    namespace_var=${namespace_var//./_}
    namespace=${!namespace_var:="\"\""}
    LINE="-Q $dir $namespace"
    echo $LINE >> $COQPROJECT_TMP
done

for dir in ${DIRS[@]}; do
    echo >> $COQPROJECT_TMP
    find $dir -iname '*.v'  >> $COQPROJECT_TMP
done

for extra in ${EXTRA[@]}; do
    if ! grep --quiet "^$extra\$" $COQPROJECT_TMP; then
        echo >> $COQPROJECT_TMP
        echo $extra >> $COQPROJECT_TMP
    fi
done


mv $COQPROJECT_TMP _CoqProject
