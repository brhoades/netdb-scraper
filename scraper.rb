require "mechanize"
require "nokogiri"
require 'highline/import'

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

fp = File.new("scraped.txt", "w")

if $user == nil 
  $user = ask("User")
end
if $pass == nil
  $pass = ask("Pass") { |q| q = q.echo = "*" }
end

$agent = Mechanize.new { |agent| agent.user_agent_alias = "Linux Mozilla" }
$agent.add_auth( "https://itweb.mst.edu/auth-cgi-bin/cgiwrap/netdb/search-hosts.pl", $user, $pass )

def scrape_names( str, mode="bydesc" )
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

  return addr
end

machines = {}
machines[:reference_machines] = scrape_names "REFERENCE"
machines[:bjrq48] = scrape_names( "bjrq48", "byname" ) 

choice = choose_machine choose_type machines
