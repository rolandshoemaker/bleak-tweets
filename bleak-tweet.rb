require 'rubygems'
require 'set'
require 'twitter'
require 'digest/md5'
require 'google-search'
require 'open-uri'
require 'RMagick'
include Magick


def generateWeightedList(wordlist)
	weighted = Array.new
	keys = wordlist.keys
	listlength = wordlist.length-1
	(0..listlength).each do |i|
		weight = wordlist[keys[i]].to_i
		(0..weight).each do |x|
			weighted << keys[i]
		end
	end
	return weighted
end

def findTweet(client, weightedlist)
	randomtag = rand(weightedlist.length)
	results = client.search("# " << weightedlist[randomtag] << " -rt", :count => 1).first
	
	unless (results.nil?)
		meh = Array.new
		meh << results.text
		meh << weightedlist[randomtag]
		return meh 
	else
		return findTweet(client, weightedlist)
	end
end

def cycle(hashlist, client, md5list, imagemd5)
	problist = generateWeightedList(hashlist)
	while
		tweet = findTweet(client, problist)
		unless (/@/.match(tweet[0]) or /http/.match(tweet[0]) or /^#/.match(tweet[0]) or md5list.include?(Digest::MD5.hexdigest(tweet[0])))
			unless (tweet[0].empty?)
				imageSearch(tweet[1], tweet[0], imagemd5)
				hashlist[tweet[1]] = hashlist[tweet[1]].to_i-1
				md5list << "#{Digest::MD5.hexdigest(tweet[0])}"
				break
			end
		end
	end
	return hashlist
end

def imageSearch(tag, tweet, imagemd5)
	Google::Search::Image.new(:query => tag).each do |image|
		unless (imagemd5.include?(Digest::MD5.hexdigest(image.uri)))
			filename = String.new
			open(image.uri) { |f|
				File.open("current", "wb") do |file|
					file.puts f.read
				end
				img = Magick::Image::read("current").first
				img.resize_to_fit!(600, 600)
				drawable = Magick::Draw.new
				
				drawable.pointsize = 18.0
				drawable.font_weight = Magick::BoldWeight

				tm = drawable.get_type_metrics(img, tweet)
				drawable.fill = 'black'
				xy1 = [0, (((img.rows)*6)/10)]
				xy2 = [(((img.columns)*8)/10), (((img.rows)*9)/10)]
				
				
				drawable.rectangle(xy1[0],xy1[1],xy2[0],xy2[1])
				drawable.draw(img)
	
				position = xy1[1]+10
				drawable.annotate(img,(xy2[0]-xy1[0])-10,(xy2[1]-xy1[1])-10,10,position += 15, wraptext(tweet, ((xy2[0]-xy1[0])-10)/10)) {self.fill='white'}
				
				filename = "testy." << img.format
				img.write(filename)
			}
			imagemd5 << "#{Digest::MD5.hexdigest(image.uri)}"
			postResult = tumblrPost(tag, filename)
			File.delete(filename)
			File.delete("current")
			writeLog(tweet, image.uri, postResult)
			break
		end
	end
end

def wraptext(text, columns)
	text.split("\n").collect do |line|
		line.length > columns ? line.gsub(/(.{1,#{columns}})(\s+|$)/, "\\1\n").strip : line
	end * "\n"
end

def do_at_exit(md5list, imagemd5)
	at_exit {
		File.open('md5list', 'w') do |f|
			md5list.to_a.each do |i|
				f.puts i
			end
		end
                File.open('imagemd5', 'w') do |f|
                        imagemd5.to_a.each do |i|
                                f.puts i
                        end
                end
	}
end

def tumblrPost(tag, filename)
	return %x( tumblr post #{filename} --host=bleak-tweets.tumblr.com )
end

def writeLog(tweet, uri, postmsg)
	File.open('log', 'a') do |f|
		f.puts "\\\\\n" <<tweet << "\n" << uri << "\n" << postmsg.chomp << "\n\\\\"
	end
end

postInterval = (60*60*24)/75	# seconds between posts where 75 is the daily limit

client = Twitter::REST::Client.new do |config|
	config.consumer_key = ""
	config.consumer_secret = ""
	config.access_token = ""
	config.access_token_secret = ""
end


md5list = IO.readlines("md5list") 
md5list = md5list.map{|x| x.chomp}
imagemd5 = IO.readlines("imagemd5")
imagemd5 = imagemd5.map{|x| x.chomp}
for y in 0..6
	hash = Hash[*File.read('word-list').split(/, |\n/)]
	for i in 0..75
		hash = cycle(hash, client, md5list, imagemd5)
		do_at_exit(md5list, imagemd5)
		sleep(postInterval)
	end
end
