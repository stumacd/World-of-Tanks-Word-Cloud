#!/usr/bin/env ruby

#----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" 
# Stuart MacDonald <stumacd@gmail.com> wrote this file. As long as you retain 
# this notice you can do whatever you want with this stuff. If we meet some day,
# and you think this stuff is worth it, you can buy me a beer in return.
# ----------------------------------------------------------------------------

# This script collects all the chat from your World of Tanks replays and saves them in a file.
# You can use this file to generate a world cloud or look back for some funny dialog aka epic rage etc.
# NOTE! The decryption of the chat block takes around 5 seconds per replay so it can take some time to finish.
# If you have any fixes/additions/interesting soliloquies patch it up and send me a pull request.

# World of Tanks Replay to json -> https://github.com/Phalynx/WoT-Replay-To-JSON (0.9.0.7 known to work)
# Full credit to Phalynx for that app :)

require 'json'

# Change this as you see fit
REPLAY_TO_JSON_APP_PATH="C:/Games/World_of_Tanks/replays/wotrp2j.exe"
WOT_REPLAY_DIRECTORY = "C:/Games/World_of_Tanks/replays"
OUTPUT_FILENAME="world_of_tanks_word_cloud_output.txt"
REMOVE_MY_CHAT = true

# Probably leave this alone - you might need to change if you use WOT in language other than english.
COLOUR_SELF="FFC364"
IGNORE_CHAT = ["Attention","Requesting","Attacking","Reloading!","Help!","Sector","Affirmative!","Negative!","Defend","Attack!"]

# Go time
begin
	out_file = File.open("#{OUTPUT_FILENAME}","w")
rescue
	puts "Unable to create: #{OUTPUT_FILENAME}"
	exit(1)
end
counter = 0
valid = 0

# Loop through the replays
Dir.glob("#{WOT_REPLAY_DIRECTORY}/*.wotreplay") do |replay|
	counter += 1
	puts " #{counter}: #{replay}"
	replay_json_filename = replay.sub("wotreplay","json")
	# Our script might be interrupted, since it takes time to do the conversion, only do it when we NEED to.
	system ("#{REPLAY_TO_JSON_APP_PATH} #{replay} -chat") unless File.exist?(replay_json_filename)
	begin
		f = File.open(replay_json_filename)
	rescue
		# Conversion didn't work :( It happens, we move on...
		next
	end
	# 3 hidden bytes at the start that screw up JSON parsing, because, why not?
	f.seek(3)

	begin
		replay_json = JSON.load(f.read)
	rescue
		# More hidden bytes - I'm not going down this rabbit hole.
		next
	end
	chat_string = replay_json["chat"]
	next if chat_string.nil?

	# We have the chat in a string now let's get the bits we want
	chat_string.split("</font><br/>").each do |line|

		next if line.include?("#{COLOUR_SELF}") and REMOVE_MY_CHAT
		text = line.sub(/.*>/,"")

		# Remove chat generated by function keys
		text_in_tokens = text.split
		next if text_in_tokens.size != (text_in_tokens - IGNORE_CHAT).size
		
		# This won't be picked up for the word cloud, but makes it easier to read the text in the output file
		text.gsub!("&apos;","'")
		text.gsub!("&quot;","\"")
		text.gsub!("&amp;","&")
		out_file.print text + " "
	end
	out_file.puts
	valid += 1
end

out_file.close
puts "Chat analyzed from #{valid}/#{counter} replays. Your data is in #{OUTPUT_FILENAME}, Enjoy!"