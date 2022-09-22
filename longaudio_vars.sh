# Copyright 2017  Speech Lab, EE Dept., IITM (Author: Srinivas Venkattaramanujam)

set -e
data_dir=data
# lang_dir=lang
# model_dir=tri3b_map_aug
lang_dir=lang_chain
model_dir=exp/tl_kids_first_try_wer_21/
graph_dir=$model_dir/graph
island_length=3
num_iters=3
iverctor_dir=exp/nnet3/ivector_for_ali