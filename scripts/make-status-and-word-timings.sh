# Copyright 2017  Speech Lab, EE Dept., IITM (Author: Srinivas Venkattaramanujam)
set -x
. ./longaudio_vars.sh
main_working_dir=$1
working_dir=$2
text_begin_index=$3
text_end_index=$4
audio_begin_time=$5
audio_end_time=$6
log_dir=$7
# create a status file which specifies which segments are done and pending
echo "Creating Alignment Status" >> $log_dir/output.log
python scripts/islands_to_status.py $working_dir/ref_and_hyp_match $working_dir/hyp_and_ref_match \
        $working_dir/text_ints $working_dir/word_alignment.ctm $working_dir/segments \
        $text_begin_index $text_end_index $audio_begin_time $audio_end_time > $working_dir/ALIGNMENT_STATUS 2> $log_dir/err.log



# save timing information for each aligned word
echo "Creating word timing" >> $log_dir/output.log
cp $main_working_dir/WORD_TIMINGS $main_working_dir/WORD_TIMINGS.tmp
cp  $main_working_dir/WORD_TIMINGS  $working_dir/WORD_TIMINGS.before
python scripts/segment_to_actual_word_time.py $main_working_dir/WORD_TIMINGS.tmp $working_dir/word_alignment.ctm $working_dir/segments $working_dir/ref_and_hyp_match $working_dir/hyp_and_ref_match $text_begin_index > $main_working_dir/WORD_TIMINGS
# rm $main_working_dir/WORD_TIMINGS.tmp
cp  $main_working_dir/WORD_TIMINGS  $working_dir/WORD_TIMINGS.after
python3 scripts/sanity_check.py $main_working_dir/WORD_TIMINGS  >  $main_working_dir/sanity.tmp

if [[ $(cat $main_working_dir/sanity.tmp) ]]; then
        utils/int2sym.pl -f 4 lang/words.txt $main_working_dir/sanity.tmp 
        exit 1;
fi

