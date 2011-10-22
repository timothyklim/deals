# encoding: utf-8

$LOAD_PATH << File.expand_path('../', __FILE__)
require 'config/environment'

# p http.response_header.status
# p http.response_header

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

    links.each_with_index do |link, index|
      link = URI.join('http://groupon.ru/', link['href']).to_s
      puts link

      http = EM::HR(link).get redirects: 1
      http.callback do
        response = Nokogiri::HTML http.response
        offers = response / 'div.offer[role=offer]'
        offers.each do |offer|
          link = (offer / 'a').first['href']

          offer_detail = EM::HR(URI.join('http://groupon.ru/', link)).get redirects: 1
          offer_detail.callback do
            response = Nokogiri::HTML offer_detail.response
            note = (response / 'div.note').first
            note = note.content if note.present?
            price = (response / 'div.price strong').first.content[/(\d+)/, 1]
            title = (response / 'h1').first.content
            puts title, price

            unless note == 'Купоны закончились.'
              timestamp = (response / 'div.time strong[data-timestamp]').first['data-timestamp']
            end
          end
        end
      end
      
      http.errback do
        puts 'Error!'
      end
    end
  end
end

puts 'Stop EM'
