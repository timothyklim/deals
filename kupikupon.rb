$LOAD_PATH << File.expand_path('../', __FILE__)
require 'config/environment'

# For short calling
def EM::HR *args
  EM::HttpRequest.new *args
end

puts 'Starting EM...'
EM.run do
  cities = EM::HR('http://www.kupikupon.ru/').get redirects: 1
  cities.callback do
    response = Nokogiri::HTML cities.response
    links = (response / 'div#city a').map {|link| link['href']}.uniq.reject {|l| l == '#'}

    links.each do |link|
      http = EM::HR("#{link}/more-deals").get redirects: 1
      http.callback do
        response = Nokogiri::HTML http.response
        # puts response
        offers = response / 'div.b-buy-box'
        offers.each do |offer|
          puts (offer / 'td.text a').first.content.strip
          puts
        end
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
