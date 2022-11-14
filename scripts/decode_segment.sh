#!/bin/bash
. ./longaudio_vars.sh
set -x



if [ $# != 5 ]; then
  echo "Usage: scripts/decode_segment.sh <segment-status> <working-dir> <log-dir> <use-nnet> <iter>"
  echo " e.g.: scripts/decode_segment.sh '0.0 1.1 PENDING 0 1' data/working_dir data/working_dir/log_dir false 0"
  echo "Description: This script generates the hypothesis for the input pending segment."
  exit 1;
fi




y=$1
working_dir=$2
log_dir=$3
use_nnet=$4
x=$5


segment_store=$working_dir/segments_store
time_begin="`echo $y | cut -d' ' -f1`"
time_end="`echo $y | cut -d' ' -f2`"
segment_id=${time_begin}_${time_end}
mkdir -p $segment_store/${segment_id}
local_data_dir=$segment_store/${segment_id}/data_dir
mkdir -p $local_data_dir 
cp -r $data_dir/{wav.scp,utt2spk,text,spk2utt,utt2dur,utt2num_frames,split1} $local_data_dir/
cp $working_dir/word_alignment.ctm $segment_store/${segment_id}/
echo "segment_$segment_id key_1 `echo $y | cut -d' ' -f 1,2 `" > $local_data_dir/segments
cp $local_data_dir/segments $segment_store/${segment_id}/
scripts/make-feats.sh $local_data_dir/segments $segment_store/$segment_id $log_dir $use_nnet || echo "make-feats failed";
# cp $data_dir/segments $segment_store/${segment_id}/segments
word_begin_index=`echo $y | cut -d' ' -f4 `
word_begin_index=$((word_begin_index+1))
word_end_index=`echo $y | cut -d' ' -f5`
word_end_index=$((word_end_index+1))
word_string=`cat $working_dir/text_actual | cut -d' ' -f $word_begin_index-$word_end_index`
word_begin_index=$((word_begin_index-1))
word_end_index=$((word_end_index-1))
echo "<s> $word_string </s>" > $segment_store/${segment_id}/lm_text
echo "$word_string" > $segment_store/${segment_id}/text_actual
cp -r $lang_dir $segment_store/$segment_id/lang_dir
if [ $x -eq $((num_iters-2)) ]; then
    scripts/build-transducer.sh $segment_store/${segment_id} $segment_store/${segment_id}/text_actual false >> $log_dir/output.log 2> $log_dir/err.log || exit 1
elif [ $x -eq $((num_iters-1)) ]; then
    scripts/build-transducer.sh $segment_store/${segment_id} $segment_store/${segment_id}/text_actual true >> $log_dir/output.log 2> $log_dir/err.log || exit 1
else
    scripts/build-trigram.sh $segment_store/${segment_id} $segment_store/${segment_id}/lm_text >> $log_dir/output.log 2> $log_dir/err.log || exit 1
fi
scripts/build-graph-decode-hyp.sh 1 decode_${segment_id} $segment_store/${segment_id} $working_dir/adapted_model_$((x-1)) $log_dir $use_nnet $local_data_dir 2> $log_dir/err.log || echo "Failed build-graph-decode" && exit 1
