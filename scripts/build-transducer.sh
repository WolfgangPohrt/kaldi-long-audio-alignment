#!/bin/bash
set -x
. ./path.sh
. ./longaudio_vars.sh

if [ $# != 3 ]; then
  echo "Usage: scripts/build-transducer.sh <working_dir> <text> <include-skip>"
  echo " e.g.: scripts/build-trigram.sh data/working_dir data/working_dir/text_actual true"
  echo "Description: This script creates a Finite Stete Grammar from the input text and saves it to <lang-dir>."
  exit 1;
fi

working_dir=$1
input_file=$2
include_skip=$3
if [ $include_skip == "false" ]; then
	echo "doing linear transducer"
	python scripts/gen_transducer.py $input_file > $working_dir/G.txt
else
	echo "doing linear transducer with skip connection"
	python scripts/gen_transducer.py $input_file --include-skip > $working_dir/G.txt
fi
fstcompile --isymbols=$lang_dir/words.txt --osymbols=$lang_dir/words.txt $working_dir/G.txt | fstdeterminizestar | fstminimize > $lang_dir/G.fst
