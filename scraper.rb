require "mechanize"
require "nokogiri"
require 'highline/import'

fp = File.new("scraped.txt", "w")

$agent = Mechanize.new { |agent| agent.user_agent_alias = "Linux Mozilla" }
$agent.add_auth( "https://itweb.mst.edu/auth-cgi-bin/cgiwrap/netdb/search-hosts.pl", ask("User"), ask("Password") { |q| q.echo = "*" } )

def scrape_names( str, mode="bydesc" )
  url = "https://itweb.mst.edu/auth-cgi-bin/cgiwrap/netdb/search-hosts.pl?mode=bydesc&search=" + str 
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

ref = scrape_names "reference"
mine = mine.union scrape_names( "bjrq48", "byname" ) 

#list.each { |i| fp.write(i.text + " \n" + i.content + "\n\n") }

