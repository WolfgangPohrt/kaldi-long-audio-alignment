<h2>Overview of the tool</h2>

Performs long audio alignment and optionally appends the segmented data to train set.


<h2>Running longaudio_alignment.sh</h2>

**Usage:**

Before running the script change the paths longaudio_vars.sh:
			
  
```bash
data_dir=path/to/data_dir
lang_dir=path/to/lang_dir
model_dir=path/to/model_dir
island_length=3 #minimum lengh of islands of conﬁdence: 
num_iters=3 #number of iteration
iverctor_dir=path/to/ivector_extractor
```


Now run the man script:
			
	 longaudio_alignment.sh [Options] <audio-path> <transcription-path> <data-dir> <working-dir>
  
     e.g.:    
	 longaudio_alignment.sh path/to/audio.wav path/to/transcription.txt data data/working_dir"
  
  Options:
  
	  --stage <stage>           		# Use stage 2 to run the itterative algorith
  
	  --create_dir (true|false) 		# Create segmented Kaldi data directory from the input (defult: false)	
	  --use_nnet (true|false)		# Use nnet acousic model.
						# If true specify <lang-dir>, <model-dir> and <iverctor-dir> in longaudio_vars.sh (default: false)

**Note:** Create path.sh and cmd.sh and create soft links to **steps** and **utils** before running the script like in Kaldi recipe.

**Note:** Iterations 0 to n-3 use trigram and iterations n-2 and n-1 are the two passes described in [2] but with a difference. the LM is built only on the exact text which corresponds to the segment rather than from a longer context hence larger deletions are still a problem.


[1]: "A RECURSIVE ALGORITHM FOR THE FORCED ALIGNMENT OF VERY LONG AUDIO SEGMENTS"

[2]: "A SYSTEM FOR AUTOMATIC ALIGNMENT OF BROADCAST MEDIA CAPTIONS USING WEIGHTED FINITE-STATE TRANSDUCERS"

