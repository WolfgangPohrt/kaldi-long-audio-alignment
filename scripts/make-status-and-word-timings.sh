set -x
. ./longaudio_vars.sh


echo "$0 $@"  # Print the command line for logging

if [ $# != 7 ]; then
  echo "Usage: scripts/make-status-and-word-timings.sh <main-working-dir> <working-dir> <text-begin-index> <text-end-index> <audio-begin-index> <audio-end-index> <log-dir>"
  echo " e.g.: scripts/make-status-and-word-timings.sh data/working_dir data/working_dir/segments_store/1 0 5 0 13.12 data/working_dir/log"
  echo "Description: This script updates the alignment and saves it to <working-dir>/WORD_ALIGNMENT"
  exit 1;
fi


main_working_dir=$1
working_dir=$2
text_begin_index=$3
text_end_index=$4
audio_begin_time=$5
audio_end_time=$6
log_dir=$7
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

