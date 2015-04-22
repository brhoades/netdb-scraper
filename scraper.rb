require "mechanize"
require "nokogiri"
require 'highline/import'
require 'json'
require 'optparse'

cache_file = "/tmp/netdb-scraped-cache.json"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: scraper.rb [options]"

  opts.on( "-c", "--credentials [FILE]","File containing credentials in cifs auth file format.") do |f|
    options[:credentials] = f
  end

  opts.on("-r", "--respawn", "Respawn this script in an xterm instance") do |r|
    options[:respawn] = r
  end

  opts.on("-f", "--force-recache", "Force a cache refresh") do |r|
    options[:recache] = r
  end
end.parse!

def choose_type machines
  i = 0
  itokey = { }
  print "Choose a type of machine:\n"
  machines.keys.each do |key|
    i += 1
    print i.to_s + ") " + key.to_s + "\n"
    itokey[i] = key
  end
  print "\n"
  choice = 0
  while choice < 1 or choice > i 
    choice = ask("Choose: ").to_i
  end
  
  machines[itokey[choice]] 
end

def choose_machine machines
  i = 0
  itoname = { }
  print "Choose a machine:\n"
  machines.each do |m|
    name = m.split('.').first
    i += 1
    print i.to_s + ") " + name + "\n"
    itoname[i] = m
  end
  choice = 0
  while choice < 1 or choice > i 
    choice = ask("Choose: ").to_i
  end
  
  itoname[choice]
end

def scrape_names( str, mode="bydesc", reg=// )
  url = "https://itweb.mst.edu/auth-cgi-bin/cgiwrap/netdb/search-hosts.pl?mode=" + mode + "&search=" + str 
  html = $agent.get(url).body
  html_doc = Nokogiri::HTML(html)

  addr = []

  list = html_doc.xpath("//tr[@class='blockTableInnerRowEven']")
  list.each do |i|
    i.text.split( "\n" ).each do |j|
      if j.match ".managed.mst.edu"
        addr << j
      end
    end
  end

  return addr.select { |m| m =~ reg }
end

if options[:respawn]
  %x(xterm -geometry 93x31+700+370 -e ruby "#{$0}"; wait )
  exit
end

if File.exists? cache_file and !options[:recache]
  $machines = JSON.parse File.read File.new cache_file
end

if ARGV.size > 0
  creds = File.new(ARGV[0])
  creds.each do |l|
    split = l.split('=')
    if split[0] == "username"
      $user = split[1].strip
    elsif split[0] == "password"
      $pass = split[1].strip
    end
  end
end

if $machines == nil
  fp = File.new(cache_file, "w")

  if $user == nil 
    $user = ask("User")
  end
  if $pass == nil
    $pass = ask("Pass") { |q| q = q.echo = "*" }
  end

  $agent = Mechanize.new { |agent| agent.user_agent_alias = "Linux Mozilla" }
  $agent.add_auth( "https://itweb.mst.edu/auth-cgi-bin/cgiwrap/netdb/search-hosts.pl", $user, $pass )
  $machines = {}
  $machines["All Reference Machines"] = scrape_names "REFERENCE", "bydesc", /^[rtcv]+[0-9]+desktop/
  $machines["My Machines"] = scrape_names "bjrq48", "byname" 
  $machines["Reference Laptops"] = $machines["All Reference Machines"].select { |m| m =~ /^rt/ }
  $machines["Reference Desktops"] = $machines["All Reference Machines"].select { |m| m =~ /^r[0-9]+/ }

  fp.write( JSON.generate $machines )
end

choice = choose_machine choose_type $machines

pid = fork do 
  exec "nohup rdp #{choice} &> /dev/null &" 
end

Process.detach pid
