set -x
. ./longaudio_vars.sh


echo "$0 $@"  # Print the command line for logging

if [ $# != 3 ]; then
  echo "Usage: scripts/make-status-and-word-timings.sh <main-working-dir> <log-dir>"
  echo " e.g.: scripts/make-status-and-word-timings.sh data/working_dir data/working_dir/log"
  echo "Description: This script updates the alignment and saves it to <working-dir>/WORD_ALIGNMENT"
  exit 1;
fi


main_working_dir=$1
log_dir=$2
iter=$3
segment_store=$main_working_dir/segments_store

while read y;do
  echo $y >> $log_dir/output.log
  time_begin="`echo $y | cut -d' ' -f1`"
  time_end="`echo $y | cut -d' ' -f2`"
  segment_id=${time_begin}_${time_end}

  if [ $iter -eq 0 ]; then
    working_dir=$main_working_dir
  else
    working_dir=$segment_store/$segment_id/
  fi


  local_data_dir=$working_dir/data_dir
  word_begin_index=`echo $y | cut -d' ' -f4 `
  word_begin_index=$((word_begin_index+1))
  word_end_index=`echo $y | cut -d' ' -f5`
  word_end_index=$((word_end_index+1))
  word_string=`cat $working_dir/text_actual | cut -d' ' -f $word_begin_index-$word_end_index`
  word_begin_index=$((word_begin_index-1))
  word_end_index=$((word_end_index-1))
  echo "<s> $word_string </s>" > $working_dir/lm_text
  echo "$word_string" > $working_dir/text_actual
  lang_dir=$working_dir/lang_dir
  echo "Creating word timing" >> $log_dir/output.log
  cp $main_working_dir/WORD_TIMINGS $main_working_dir/WORD_TIMINGS.tmp
  cp  $main_working_dir/WORD_TIMINGS  $working_dir/WORD_TIMINGS.before

  python scripts/segment_to_actual_word_time.py $main_working_dir/WORD_TIMINGS.tmp $working_dir/word_alignment.ctm $working_dir/segments $working_dir/ref_and_hyp_match $working_dir/hyp_and_ref_match $word_begin_index > $main_working_dir/WORD_TIMINGS
cp  $main_working_dir/WORD_TIMINGS  $working_dir/WORD_TIMINGS.after
done < <(cat $main_working_dir/ALIGNMENT_STATUS | grep PENDING)