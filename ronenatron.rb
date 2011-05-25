#!/usr/bin/env ruby
# ronenv famotron
# measure proliferation on the web
# * peope who liked the videos
# * google search results
#
# Store results as JSON arrays with as much metadata as possible
# and as raw text files of just URLs that can be piped into the browser

require 'rubygems'
require 'mechanize'
require 'json'
require 'cgi'

videos = [
  {:name => "Ronen's Lifesize Ballerina Music Box", :id => '24033420' },
  {:name => "Ronen's Adventure: Trapped in an iPhone", :id => '23715004' },
  {:name => "NYC DiningCar: A 6-Course Dinner Party on the NYC Subway", :id => '23489190' },
  {:name => "REGGIE WATTS: IMPROVISED DECONSTRUCTION", :id => '23059236' },
  {:name => "How To Cook Beef Stroganoff and Fight Off A Ninja", :id => '22767968'}
]

def vimeo_likers(video_id,page=1)
  # TODO add Vimeo oauth service object
  service = Service.vimeo.first
  body = service.send(:token_object).get("http://vimeo.com/api/rest/v2?method=vimeo.videos.getLikers&video_id=#{video_id}&per_page=50").body; puts body.length
  users = (doc/'user').map{|x| {:name => x['display_name'], :url => "http://vimeo.com/"+x['username']} }
  urls = users.map{|x| x[:url] }
  File.open("vimeo-likers-#{video_id}.csv", "a+") do |f|
    f.write(urls.join("\n"))
  end
  return users
end

def google_results(_q)
  q = CGI.escape(_q)
  pages = 10
  start_page = 1
  current_page, per_page = start_page, 10 # googlecontrolled
  agent = Mechanize.new
  links = []
  # threads = []
  while current_page <= pages
    # threads << Thread.new do
      url = "http://www.google.com/search?q=#{q}&hl=en&start=#{current_page*per_page}"
      # STDERR.puts "Page #{current_page} url=#{url.inspect}"
      doc = agent.get(url)
      res = (doc/'h3 a').map{|x| {:href => x['href'], :name => x.content} }
      links += res
    # end
    current_page += 1
    sleep 1
  end
  # threads.map{|x| x.join }
  return links.flatten.compact
end

# Get all Vimeo likers and print
users = []
videos.each do |video|
  while true
    likers = vimeo_likers
    break if likers.blank?
    users += likers
    page += 1
  end
end

users = users.compact.flatten
urls = users.map{|x| x[:href] }

File.open("likers.json", "w") do |f|
  f.write(JSON.pretty_generate(users))
end

File.open("likers.txt", "w") do |f|
  f.write(urls.join("\n"))
end


# Get all Google search result URLs and print
queries = ['"how to cook" stroganoff ninja']
queries.each_with_index do |q,i|
  links = google_results(q)

  File.open("urls#{i}.json", "w") do |f|
    f.write(JSON.pretty_generate(links))
  end

  File.open("urls#{i}.txt", "w") do |f|
    f.write(links.join("\n"))
  end

end

puts "Done"
exit 0
