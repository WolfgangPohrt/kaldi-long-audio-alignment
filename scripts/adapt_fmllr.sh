

data_dir=$1
working_dir=$2
model_dir=$3
iter=$4

. ./longaudio_vars.sh
set -x

echo "$0 $@"  # Print the command line for logging

if [ $# != 4 ]; then
  echo "Usage: scripts/adapt_fmllr.sh <data-dir> <working-dir> <model-dir> <iter>"
  echo " e.g.: scripts/adapt_fmllr.sh data data/working_dir exp/tri3b 0"
  echo "Description: This script does 2 iterations of fMLLR estimation using the reliably aligned regions using steps/align_fmllr.sh ."
  exit 1;
fi




[ -d $working_dir/adapted_model_$iter ] || mkdir  $working_dir/adapted_model_$iter
[ -d $working_dir/reliable_regions_$iter ] || mkdir  $working_dir/reliable_regions_$iter
cp $data_dir/wav.scp $working_dir/reliable_regions_$iter
python3 scripts/aligned_regions.py $working_dir/ALIGNMENT_STATUS $working_dir $working_dir/reliable_regions_$iter
utils/fix_data_dir.sh $working_dir/reliable_regions_$iter
steps/make_mfcc.sh --nj 1 $working_dir/reliable_regions_$iter
steps/compute_cmvn_stats.sh  $working_dir/reliable_regions_$iter
steps/align_fmllr.sh --nj 1 $working_dir/reliable_regions_$iter $lang_dir $model_dir $working_dir/adapted_model_$iter
