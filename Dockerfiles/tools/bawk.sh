#!/bin/bash
#
# Copyright 2008,2010 Ivan Molineris <ivan.molineris@gmail.com>; 2008,2010 Gabriele Sales <gbrsales@gmail.com>

full_version="no"
for i in "$@"; do
        if [[ $i == "-M" ]] || [[ ${i:0:1} == '-' ]] || [[ $i =~ \$[0-9]*_?[a-zA-Z] ]] || [[ $i =~ \$[0-9]+~[0-9]+ ]]; then
                full_version="yes"
                break
        fi
done

if [[ $@ =~ \.gz$ ]]; then
        full_version="yes"
fi

if [[ $@ =~ \.xz$ ]]; then
        full_version="yes"
fi

full_version="no"
if [[ $full_version == "yes" ]]; then
        exec bawk_ext -v OFMT='%.17g' -v CONVFMT='%.17g' "$@"
else
        export LC_ALL=POSIX
        exec gawk -F'\t' -v OFS='\t' -v OFMT='%.17g' -v CONVFMT='%.17g' --re-interval "$@"
fi
