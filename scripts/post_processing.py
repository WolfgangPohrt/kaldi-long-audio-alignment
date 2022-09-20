import tgt
import sys
import os
from tgt.core import Interval, IntervalTier, TextGrid


input_path = sys.argv[1]
output_dir = sys.argv[2]


basename = os.path.basename(input_path)
output_path = os.path.join(output_dir, basename)

grid = tgt.io.read_textgrid(input_path)
# intervals = grid.tiers[0].annotations

# # for kalid long alignment unaligned words #
# for i, inter in enumerate(intervals):
#     unali_words = []
#     unali_regions = []
#     unali_fl = False
#     if inter.start_time == -1:
#         start_time = intervals[i-1].end_time
#         unali_fl = True
#     if unali_fl == True:
#         unali_words.append(inter.text)
#     if unali_fl == True and inter.start_time != -1:
#         end_time = inter.end_time
#         unali_fl = False
#         unali_words = []
#         unali_regions.append(Interval(start_time, end_time, ' '.join(unali_words)))
# grid.tiers[0].delete_annotation_by_start_time(-1)
# for region in unali_regions:
#     grid.tiers[0].add_annotation(region)

# print(grid.tiers[0])