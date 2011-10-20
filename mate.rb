$LOAD_PATH << File.expand_path('../', __FILE__)
require 'config/environment'

# For short calling
def EM::HR *args
  EM::HttpRequest.new *args
end

puts 'Starting EM...'
EM.run do
  cities = EM::HR('http://groupon.ru/').get redirects: 1
  cities.callback do
    response = Nokogiri::HTML cities.response
    links = response / 'div.cities a'

    links.each do |link|
      puts URI.join('http://groupon.ru/', link['href']).to_s
      city = EM::HR(URI.join('http://groupon.ru/', link['href']).to_s).get redirects: 1
      city.callback do
        puts city.response
      end
    end
  end

  # http = EM::HR('http://groupon.ru/moscow').get
  # http.callback do
  #   # p http.response_header.status
  #   # p http.response_header
  #   response = Nokogiri::HTML http.response
  #   offers = response / 'div.offer[role=offer]'
  #   offers.each do |offer|
  #     puts (offer / 'h2').first.content.strip
  #     puts
  #   end
  # 
  #   EM.stop
  # end
  # 
  # http.errback do
  #   puts 'Error!'
  # end
end

puts 'Stop EM'
