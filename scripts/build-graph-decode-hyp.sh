#!/bin/bash

# Copyright 2017  Speech Lab, EE Dept., IITM (Author: Srinivas Venkattaramanujam)

set -x
export KALDI_ROOT=/home/theokouz/kaldi/
source $KALDI_ROOT/tools/config/common_path.sh

. ./longaudio_vars.sh


echo "$0 $@"  # Print the command line for logging

if [ $# != 6 ]; then
  echo "Usage: scripts/build-graph-decode-hyp.sh <num_job> <decode-dir> <working-dir> <model-dir> <log-dir> <use-nnet>"
  echo " e.g.: scripts/build-graph-decode-hyp.sh 16 decode data/working_dir exp/tri3b data/working_dir/log_dir false"
  echo "Description: This script creates a decoding graph, performs decoding using decode_fmllr.sh, and matches hypothesis with reference text using SCLITE."
  exit 1;
fi



nj=$1
decode_dir=$2
working_dir=$3
model_dir=$4
log_dir=$5
use_nnet=$6


utils/mkgraph.sh $lang_dir $model_dir $graph_dir >> $log_dir/output.log 2> $log_dir/err.log || exit 1
rm -rf $model_dir/$decode_dir
mkdir -p $model_dir/$decode_dir/scoring

# steps/decode.sh --cmd "run.pl"  --nj $nj --skip-scoring true $graph_dir $data_dir $model_dir/$decode_dir >> $log_dir/output.log 2> $log_dir/err.log || exit 1
if [ $use_nnet == "true" ]; then
        steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
                --nj 1 --cmd "$decode_cmd" \
                --skip-scoring true \
                --online-ivector-dir $iverctor_dir \
                $graph_dir $data_dir $model_dir/$decode_dir
else
        scripts/decode_fmllr.sh --cmd "run.pl --mem 2G" --nj 1 --skip_scoring true $graph_dir $data_dir $model_dir/$decode_dir >> $log_dir/output.log 2> $log_dir/err.log || exit 1
fi


(lattice-scale --inv-acoustic-scale=10 "ark:gunzip -c $model_dir/$decode_dir/lat.*.gz|" ark:- 2> $log_dir/err.log || exit 1)  | \
        (lattice-add-penalty --word-ins-penalty=10.0 ark:- ark:- 2> $log_dir/err.log || exit 1) | \
        (lattice-best-path --word-symbol-table=$lang_dir/words.txt ark:- ark,t:$model_dir/$decode_dir/scoring/10.tra 2> $log_dir/err.log || exit 1 )
(cat $model_dir/$decode_dir/scoring/10.tra 2> $log_dir/err.log || exit 1) | sed 's/segment_//g' | sort -k1n | cut -d' ' -f2- | tr '\n' ' ' | tr -s ' ' > $working_dir/hypothesis.tra

(python scripts/sym2int.py $lang_dir/words.txt $working_dir/text_actual 2> $log_dir/err.log || exit 1 )| tr -s ' ' > $working_dir/text_ints

(lattice-add-penalty --word-ins-penalty=10.0 ark:"gunzip -c $model_dir/$decode_dir/lat.*.gz|" ark:- 2> $log_dir/err.log || exit 1)| \
(lattice-1best  --acoustic-scale=0.1 ark:- ark:- 2> $log_dir/err.log || exit 1) | \
(lattice-align-words $lang_dir/phones/word_boundary.int $model_dir/final.mdl ark:- ark:- 2> $log_dir/err.log || exit 1) | \
(nbest-to-ctm ark:- - 2> $log_dir/err.log || exit 1) | sed 's/segment_//g' | sort -s -k 1,1n | sed 's/^/segment_/g' > $working_dir/word_alignment.ctm

# note: multiple spaces before key makes sclite fail and number of lines should match 
(cat $working_dir/hypothesis.tra 2> $log_dir/err.log || exit 1) | sed 's/$/ (key_1)\n/' | tr -s ' '> $working_dir/hypothesis.tra_rm
(cat $working_dir/text_ints 2> $log_dir/err.log || exit 1) | sed 's/$/ (key_1)\n/' | tr -s ' ' > $working_dir/text_ints_rm
#echo "Text-Text alignment using sclite"
sclite -p -i 'rm' -r $working_dir/text_ints_rm -h $working_dir/hypothesis.tra_rm > $working_dir/ref_and_hyp 2> $log_dir/err.log || (echo "sclite failure" && exit 1)
sclite -p -i 'rm' -r $working_dir/hypothesis.tra_rm -h $working_dir/text_ints_rm > $working_dir/hyp_and_ref 2> $log_dir/err.log || (echo "sclite failure" && exit 1)

# clean up ref_and_hyp & hyp_and_ref to have only C,I,D,S characters
(cat $working_dir/ref_and_hyp 2> $log_dir/err.log || exit 1) | sed '/[<"]/d' | sed '/^\n/d' | tr '\n' ' ' | sed 's/ //g'  \
        > $working_dir/ref_and_hyp.final
(cat $working_dir/hyp_and_ref 2> $log_dir/err.log || exit 1) | sed '/[<"]/d' | sed '/^\n/d' | tr '\n' ' ' | sed 's/ //g'  \
        > $working_dir/hyp_and_ref.final

# word indexes for matching segments
echo "Obtaining aligned word indices in both reference and hypothesis"
python scripts/correct_segment.py $working_dir/ref_and_hyp.final $island_length > \
        $working_dir/ref_and_hyp_match 2> $log_dir/err.log || exit 1
python scripts/correct_segment.py $working_dir/hyp_and_ref.final $island_length > \
        $working_dir/hyp_and_ref_match 2> $log_dir/err.log || exit 1
((`wc -l $working_dir/ref_and_hyp_match | cut -d' ' -f1` == `wc -l $working_dir/hyp_and_ref_match \
        | cut -d' ' -f1`)) || \
        (echo 'Number of correct segments not matching' && exit 1)

