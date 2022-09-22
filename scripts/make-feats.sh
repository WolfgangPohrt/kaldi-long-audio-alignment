#!/bin/bash

# Copyright 2017  Speech Lab, EE Dept., IITM (Author: Srinivas Venkattaramanujam)
# set -x
. ./longaudio_vars.sh
source_file=$1
working_dir=$2
log_dir=$3
use_nnet=$4
set -x

echo "$0 $@"  # Print the command line for logging

if [ $# != 4 ]; then
  echo "Usage: scripts/make-feats.sh <data-dir> <working-dir> <log-dir> <use-nnet>"
  echo " e.g.: scripts/scripts/make-feats.sh data data/working_dir data/working_dir/log_dir false"
  echo "Description: This script creates utt2spk, spk2utt and extracts features."
  exit 1;
fi





cut -d' ' -f1<$source_file > $working_dir/utt 2> $log_dir/err.log
paste $working_dir/utt $working_dir/utt | sort > $data_dir/utt2spk
cp $data_dir/utt2spk $data_dir/spk2utt  
rm $working_dir/utt
(rm $data_dir/feats.scp $data_dir/cmvn.scp || echo "") >> $log_dir/output.log 2>&1


if [ $use_nnet == "true" ]; then 
    mfcc_config=conf/mfcc_hires.conf
    steps/make_mfcc.sh --mfcc-config $mfcc_config  --nj 1  $data_dir $working_dir/tmp/logdir/ $working_dir/tmp/mfccdir >> $log_dir/output.log 2> $log_dir/err.log
    steps/compute_cmvn_stats.sh $data_dir $working_dir/tmp/logdir/ $working_dir/tmp/cmvndir >> $log_dir/output.log 2> $log_dir/err.log
    nspk=$(wc -l <$data_dir/spk2utt)
    steps/online/nnet2/extract_ivectors_online.sh  \
        --cmd "run.pl" --nj "${nspk}" \
        $data_dir exp/nnet3/extractor \
        exp/nnet3/ivector_for_ali

else    
    steps/make_mfcc.sh --nj 1  $data_dir $working_dir/tmp/logdir/ $working_dir/tmp/mfccdir >> $log_dir/output.log 2> $log_dir/err.log
    steps/compute_cmvn_stats.sh $data_dir $working_dir/tmp/logdir/ $working_dir/tmp/cmvndir >> $log_dir/output.log 2> $log_dir/err.log
fi
