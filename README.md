# World-of-Tanks-Word-Cloud
Puts all the chat from your World of Tanks replays into a file so that you can create a word cloud.

## How it works
It takes each replay and gets the text component and puts this in a file.
Extracting the text from a replay can take around 10 seconds, so this can take a long time if you have a lot of replays.

## Usage
* Install the [Ruby programming language](http://rubyinstaller.org/).
* Ensure that ruby is added to your path
* Download [this](https://github.com/stumacd/World-of-Tanks-Word-Cloud/archive/master.zip) repository as a zip.
* Unzip the files.
* I have included a compiled version of [Wotrp2j]((https://github.com/Phalynx/WoT-Replay-To-JSON)) (and the two files that it requires) as it isn't the easiest thing to create for oneself.
run this script:
```bash
ruby wot_word_cloud.rb -r <REPLAY_DIR> -j <PATH_TO_WOTRP2J.EXE>
```
E.g.
```bash
ruby wot_word_cloud.rb -r C:\Games\World_Of_Tanks\replays -j C:\Games\World_Of_Tanks\wotrp2j.exe
```
For more options:
```bash
ruby wot_word_cloud.rb --help
```
## Credit
[Phalynx's WoT-Replay-To-JSON](https://github.com/Phalynx/WoT-Replay-To-JSON) does the heavy lifting.

## Future
If anyone wants to add any features, I am happy to integrate them if I think there is a interesting use case. eg. Filter the games by type or tier etc.
