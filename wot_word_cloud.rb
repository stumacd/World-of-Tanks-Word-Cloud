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
require 'optparse'

options = {}

options[:mychat] = true
options[:platoonchat] = true
options[:teamchat] = true
options[:enemychat] = true

opt_parser = OptionParser.new do |opts|

  opts.banner = "Usage: ruby wot_word_cloud.rb [options]"
  
  opts.on('-r', '--replaydir STR','Replay Directory Path') do |replay_dir|
    options[:replay_dir] = replay_dir.strip.gsub('\\','/')
  end
  
  opts.on('-o', '--outputfile STR','Output File where the text will be printed') do |output_file|
    options[:output_file] = output_file.strip
  end
  
  opts.on('-j', '--jsonconverter STR','Replay to JSON converter location') do |json_path|
    options[:json_path] = json_path.strip
  end

  opts.on('-m','--mask STR','Mask Chat - 1 true, 0 false - My chat | Platoon Chat | Friendly Team Chat | Enemy Team Chat ') do |mask|
    # Test mask is 4 and only 0's and 1's
    mask.strip!
    break if mask !~ /[0,1]{4}/
    # Assign
     options[:mychat] = mask[0] == "1"
     options[:platoonchat] = mask[1] == "1" 
     options[:teamchat] = mask[2] == "1"
     options[:enemychat] = mask[3] == "1"
  end

  opts.on('-n', '--name NAME','Put your ingame name to speed things up') do |name|
    options[:name] = name.strip
  end

end

opt_parser.parse!

# Print or Abort if invalid

# Required options

if options[:replay_dir].nil?
  abort("No replay directory specified.")
else
  puts "WOT Replay directory: " + options[:replay_dir]
end

if options[:json_path].nil?
  abort("Replay to JSON converter location not specified.")
else
  puts "Replay to JSON converter location: " + options[:json_path]
end

# Optional options

if options[:output_file].nil?
  options[:output_file] = "#{options[:replay_dir]}/world_of_tanks_word_cloud_output.txt"
end
puts "Output File where the text will be printed: " + options[:output_file]
puts ""

if options[:mychat].nil?
  # No mask specified so record all chat
  options[:mychat] = true
  options[:platoonchat] = true
  options[:teamchat] = true
  options[:enemychat] = true
end

# Probably leave this alone - you might need to change if you use WOT in language other than english.
IGNORE_CHAT = ["Attention","Requesting","Attacking","Reloading","Help!","Sector","Affirmative!","Negative!","Defend","Attack!","spotted","Spotted","Ready","Shells","seconds","Refilling","Reloading!"]
colours = {
            "FFC364" => :platoonchat,
            "80D63A" => :teamchat,
            "DA0400" => :enemychat
          }
          
# Go time
begin
	out_file = File.open("#{options[:output_file]}","w")
rescue
	abort("Unable to create: #{options[:output_file]}")
end

# Init loop vars
counter = 0
valid = 0

# Loop through the replays
Dir.glob("#{options[:replay_dir]}/*.wotreplay") do |replay|
	counter += 1
	puts " #{counter}: #{replay}"
	replay_json_filename = replay.sub("wotreplay","json")
	# Our script might be interrupted, since it takes time to do the conversion, only do it when we NEED to.
	system ("#{options[:json_path]} #{replay} -chat") unless File.exist?(replay_json_filename)
	begin
		f = File.open(replay_json_filename)
	rescue
		puts "Unable to open #{replay_json_filename}, perhaps the conversion failed."
		next
	end
	# 3 hidden chars at the start that screw up JSON parsing, because, why not?
	f.seek(3)

	begin
		replay_json = JSON.load(f.read)
	rescue
		# More hidden bytes - I'm not going down this rabbit hole atm.
		# TODO loop moving the file ptr and see if there is an accepted json format
		next
	end

	next if replay_json.nil?
	chat_string = replay_json["chat"]
	next if chat_string.nil?
		
	# We have the chat in a string now let's get the bits we want
	chat_string.split("</font><br/>").each do |line|
	    col = line.split("\\'")[1].delete("#")
		chat_type = colours[col]
	    next if chat_type.class != Symbol
    	# This chat is to be excluded from the results by the user

    	if chat_type.eql?(:platoonchat)
    		myname = options[:name] || replay_json["identify"]["playername"]
    		if line.include?(myname)
    			chat_type = :mychat
    		end
    	end

		next if (options[chat_type] == false)
		text = line.sub(/.*>/,"")

		# Remove chat generated by function keys
		text_in_tokens = text.split
		next if text_in_tokens.size != (text_in_tokens - IGNORE_CHAT).size
		
		# This won't be picked up for the word cloud, but makes it easier to read the text
		# in the output file and removes them from the word cloud
		text.gsub!("&apos;","'")
		text.gsub!("&quot;","\"")
		text.gsub!("&amp;","&")
		out_file.print text + " "

	end
	out_file.puts
	valid += 1

end

out_file.close

puts ""
puts "There will be some .json, .tmp and .tmp.out files in your replay directory, delete these if you no longer need them."
puts ""
puts "Chat analyzed from #{valid}/#{counter} replays. Your data is in #{options[:output_file]}, Enjoy!"
