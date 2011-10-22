# http://kuponator.ru/

$LOAD_PATH << File.expand_path('../', __FILE__)
require 'config/environment'

# For short calling
def EM::HR *args
  EM::HttpRequest.new *args
end

puts 'Starting EM...'
EM.run do
  cities_with_deals_count = {}

  cities = EM::HR('http://www.kupikupon.ru/').get redirects: 1
  cities.callback do
    response = Nokogiri::HTML cities.response
    links = (response / 'div#city a').map {|link| link['href']}.uniq.reject {|l| l == '#' or not l =~ /\.ru\//}

    links.each do |link|
      http = EM::HR("#{link}/more-deals").get redirects: 1
      http.callback do
        city = link[/\/([^\/]+)$/,1]
        response = Nokogiri::HTML http.response
        offers = response / 'div.b-buy-box'
        cities_with_deals_count[city] = offers.count

        offers.each do |offer|
          content = (offer / 'td.text a').first.content.strip
          puts "#{city}: #{content}\n"
        end

        ap Hash[cities_with_deals_count.to_a.sort {|c, n| c[1] <=> n[1]}]
      end
      
      http.errback do
        puts 'Error!'
      end
    end
  end

  cities.errback do
    puts 'Error!'

    EM.stop
  end
end

puts 'Stop EM'
