# kaldi-long-audio-alignment
Long audio alignment using Kaldi. This tool splits a long audio and the corresponding transcript into multiple segments such that the transcripts for smaller segment correspond to the small audio segment. It is useful in ASR training since the small segments take much lesser total time compared to using the entire audio at once.

The algorithm is similar to the one in SAILALIGN toolkit (https://github.com/nassosoassos/sail_align).

Refer to "A RECURSIVE ALGORITHM FOR THE FORCED ALIGNMENT OF VERY LONG AUDIO SEGMENTS" and "A SYSTEM FOR AUTOMATIC ALIGNMENT OF BROADCAST MEDIA CAPTIONS USING WEIGHTED FINITE-STATE TRANSDUCERS" to get started.

**NOTE:** Adaptation after each pass has not been implemented yet.

**License:** Apache License 2.0

**Copyright:** Speech Lab (of [Prof. S Umesh](http://www.ee.iitm.ac.in/~umeshs/)), EE department, IIT Madras


<h2>Overview of the tool</h2>

Performs long audio alignment and optionally appends the segmented data to train set.


<h2>Running longaudio_alignment.sh</h2>

**Usage:** longaudio_alignment.sh <audio-path> <transcription-path> <data-dir> <working-dir>
  e.g.:    longaudio_alignment.sh path/to/audio.wav path/to/transcription.txt data data/working_dir"
  Options:
    --stage <stage>           # Use stage 2 to run the itterative algorith
    --create_dir (true|false) 		# create segmentd kaldi data directory from the input (defult: false)

**Note:** Iterations 0 to n-3 use trigram and iterations n-2 and n-1 are the two passes described in [2] but with a difference. the LM is built only on the exact text which corresponds to the segment rather than from a longer context hence larger deletions are still a problem.


[1]: "A RECURSIVE ALGORITHM FOR THE FORCED ALIGNMENT OF VERY LONG AUDIO SEGMENTS"

[2]: "A SYSTEM FOR AUTOMATIC ALIGNMENT OF BROADCAST MEDIA CAPTIONS USING WEIGHTED FINITE-STATE TRANSDUCERS"
