#!/bin/bash

# Copyright 2017  Speech Lab, EE Dept., IITM (Author: Srinivas Venkattaramanujam)

. ./path.sh # ensure kaldi, IRSTLM and sctk are in path
. ./cmd.sh
. ./longaudio_vars.sh
set -e
set -x
stage=2
create_dir=false
create_dir=false
use_nnet=false


echo "$0 $@"  # Print the command line for logging
. parse_options.sh || exit 1;

if [ $# != 5 ]; then
  echo
  echo "Usage: longaudio_alignment.sh <audio-path> <transcription-path> <data-dir> <working-dir>"
  echo " e.g.: longaudio_alignment.sh path/to/audio.wav path/to/transcription.txt data data/working_dir"
  echo
  echo "Options: "
  echo "  --stage <stage>   			# Use stage 2 to run the itterative algorith."
  echo "  --create_dir (true|false) 		# create segmentd kaldi data directory from the input. (defult: $create_dir)"
  echo "  --use_nnet (true|false) 		# Use nnet model instead of gmm. If true specify <lang-dir>, <model-dir> and <iverctor-dir> in longaudio_vars.sh.  (defult: $use_nnet)"
  echo
  exit 1;
fi



audio=$1
text=$2
data_dir=$3
working_dir=$4


if [ -d "$data_dir" ]; then rm -rf $data_dir; fi


mkdir -p $data_dir

# create wav.scp and text
echo "key_1 $audio" > $data_dir/wav.scp
sed '/^[[:space:]]*$/d' $text > $data_dir/text
sed -i -e 's/^/key_1 /' $data_dir/text


segment_store=$working_dir/segments_store
log_dir=$working_dir/log
mkdir -p $working_dir
mkdir -p $log_dir
mkdir -p $segment_store
cp -r $lang_dir $working_dir/lang_dir
echo "Params: working_dir=$working_dir log directory=$log_dir"
(rm $data_dir/segments || echo "") >> $log_dir/output.log 2>&1
echo "Making feats"
scripts/make-feats.sh $data_dir/wav.scp $working_dir $log_dir $use_nnet 2> $log_dir/err.log

# VAD and segmentation based on VAD
echo "Doing VAD"

# # This uses SailAlign's VAD
# ./bin/vad -i $audio -m bin/MattModel.bin -o $working_dir/vad.tmp 2> $log_dir/err.log || exit 1
# awk '{print $2}' $working_dir/vad.tmp | tr -d '\n' > $working_dir/vad.ark 

# This uses Kaldi's VAD.
(compute-vad scp:$data_dir/feats.scp ark,t:- 2> $log_dir/err.log || exit 1) | cut -d' ' -f2- | tr -d ' '|tr -d '[' | tr -d ']'  > $working_dir/vad.ark || exit 1

echo "Making segments using VAD"
# split_vad.py considers even one frame of 0 (silence) as potential breakpoint. But you might want to change it
(python scripts/split_vad.py $working_dir/vad.ark  2> ${log_dir}/err.log || exit 1) | sort > $data_dir/segments 


cp $data_dir/segments $working_dir/segments 2> $log_dir/err.log || exit 1
echo "Computing features for segments obtained using VAD"
scripts/make-feats.sh $data_dir/segments $working_dir $log_dir $use_nnet 2>${log_dir}/err.log
# prepare text fileS

echo "Preparing text files: text_actual"
(cat $data_dir/text 2> $log_dir/err.log || exit 1) | cut -d' ' -f2- | sed 's/^ \+//g' | sed 's/ \+$//g' | tr -s ' ' > $working_dir/text_actual 

echo "Preparing text files: lm_text"
(cat $working_dir/text_actual 2> $log_dir/err.log || exit 1) | sed -e 's:^:<s> :' -e 's:$: </s>:' > $working_dir/lm_text

echo "Preparing text files: initializing WORD_TIMINGS file with all -1 -1"
(python scripts/sym2int.py ${lang_dir}/words.txt  $working_dir/text_actual 2> $log_dir/err.log || exit 1) | tr ' ' '\n' | sed 's/$/ -1 -1/g' > $working_dir/WORD_TIMINGS
echo "Preparation of text files over"



#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------#


echo "Preparing trigram LM"
scripts/build-trigram.sh $working_dir $working_dir/lm_text >> $log_dir/output.log 2> $log_dir/err.log || exit 1
echo "Trigram LM created using $working_dir/lm_text"

# build graph and decode
echo "Executing build-graph-decode-hyp.sh"
num_lines=`wc -l $data_dir/feats.scp | cut -d' ' -f1` # min of num_lines and 20 for num_jobs
scripts/build-graph-decode-hyp.sh $(($num_lines>20?20:$num_lines)) decode $working_dir $model_dir $log_dir $use_nnet $data_dir 2> $log_dir/err.log || exit 1
echo "iter 0 decode over"


# create a status file which specifies which segments are done and pending and save timing information for each aligned word
num_text_words=`wc -w $working_dir/text_ints | cut -d' ' -f1`
text_end_index=$((num_text_words-1))
audio_duration=`(wav-to-duration --read-entire-file scp:$data_dir/wav.scp ark,t:- 2>> $log_dir/output.log) | cut -d' ' -f2`
python3 scripts/anchor_to_status.py $working_dir/WORD_TIMINGS $audio_duration > $working_dir/ALIGNMENT_STATUS

scripts/make-status-and-word-timings.sh $working_dir $log_dir 0 2> $log_dir/err.log 

cp -r $model_dir $working_dir/adapted_model_0


if [ $stage -ge 2 ]; then 
segment_id=`wc -l $working_dir/segments | cut -d' ' -f1`
for x in `seq 1 $((num_iters-1))`;do

	while read y;do

		scripts/decode_segment.sh "$y" $working_dir $log_dir $use_nnet $x &
		# At most as number of CPU cores
		[ $( jobs | wc -l ) -ge 6 ] && wait


	done < <(cat $working_dir/ALIGNMENT_STATUS | grep PENDING)
	wait

	scripts/make-status-and-word-timings.sh $working_dir $log_dir 1
	python3 scripts/anchor_to_status.py $working_dir/WORD_TIMINGS $audio_duration > $working_dir/ALIGNMENT_STATUS

	if [[ $(grep PENDING $working_dir/ALIGNMENT_STATUS) ]]; then
		scripts/adapt_fmllr.sh $data_dir $working_dir $working_dir/adapted_model_$((x-1)) $x
	else
		echo "Finished successfully"
	fi
done;
fi
echo "Final alignment "
utils/int2sym.pl -f 1 $lang_dir/words.txt  $working_dir/WORD_TIMINGS | awk '{print $2, $3, $1}' >  $working_dir/WORD_TIMINGS.lab

if [ $create_dir == "true" ]; then
	echo "Creating $new_dir"
	mkdir -p $new_dir
	x=`echo "$data_dir" | rev | cut -d'/' -f1 | rev`
	# the following script makes a segment with 10 words but if there is no timing info for the 10th word, we proceed until we find a word with known timing
	scripts/timing_to_segment_and_text.py $working_dir/WORD_TIMINGS.words $x $new_dir/segments $new_dir/text `(wav-to-duration --read-entire-file scp:${data_dir}/wav.scp ark,t:- 2>> $log_dir/output.log) | cut -d' ' -f2`
	echo "${x} `cat ${data_dir}/wav.scp|cut -d' ' -f2-`" > $new_dir/wav.scp
	cut -d ' ' -f1 $new_dir/segments | sed "s/$/ $x/g" > $new_dir/utt2spk
	cut -d ' ' -f1 $new_dir/segments | sed "s/^/$x /g" > $new_dir/spk2utt
fi


