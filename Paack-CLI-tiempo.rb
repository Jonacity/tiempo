#!/usr/bin/env ruby

require 'open-uri'
require 'json'
require 'nokogiri'
require 'net/http'
require 'active_support/core_ext/hash'

@paack_id = "&affiliate_id=zdo2c683olan"
@url_location = "https://www.tiempo.com/peticionBuscador.php?lang=es&texto="
@url_city_details = "http://api.tiempo.com/index.php?api_lang=es&localidad="

def get_city_id(city)
    url_city = @url_location + city
    city_serialized = open(url_city).read
    city_details = JSON.parse(city_serialized)

    if city_details["localidad"].empty?
        return
    else
        city_id = city_details["localidad"][0]["id"]
        return city_id
    end
end

def get_city_details(id)
    city_xml_file = @url_city_details + id.to_s + @paack_id

    details_xml_file = Net::HTTP.get_response(URI.parse(city_xml_file)).body
    details_json_file = Hash.from_xml(details_xml_file).to_json
    details = JSON.parse(details_json_file)

    return details
end

def week_av_min(data)
    sum_min = 0
    week_min = data["report"]["location"]["var"][0]["data"]["forecast"]

    week_min.each do |val|
        sum_min += val["value"].to_i
    end

    av_min = sum_min / 7
    return av_min
end

def week_av_max(data)
    sum_max = 0
    week_max = data["report"]["location"]["var"][1]["data"]["forecast"]

    week_max.each do |val|
        sum_max += val["value"].to_i
    end

    av_max = sum_max / 7
    return av_max
end

def today_av(data)
    day = Date.today.wday

    today_temp_min = data["report"]["location"]["var"][0]["data"]["forecast"][day]["value"].to_i
    today_temp_max = data["report"]["location"]["var"][1]["data"]["forecast"][day]["value"].to_i

    temp = (today_temp_min + today_temp_max) / 2
    return temp
end

def valid_city?(city)
    city.match(/^[a-zA-Z]+(?:[\s-][a-zA-Z]+)*$/)
end

def weather_check
    city = gets.chomp.downcase

    if valid_city?(city)
        id = get_city_id(city)

        if id 
            data = get_city_details(id)
            av_min = week_av_min(data)
            av_max = week_av_max(data)
            temp_today = today_av(data)
        
            puts "*************************"
            puts "#{city.capitalize} weather:"
            puts "Average minimum temperature of the week: #{av_min.to_s}°"
            puts "Average maximum temperature of the week: #{av_max.to_s}°"
            puts "Average temperature of the day: #{temp_today.to_s}°"
        else
            puts "*************************"
            puts "No data for this city..."
            puts "> Try another city"

            weather_check
        end
    else
        puts "*************************"
        puts "> Please enter a valid city name"

        weather_check
    end 
end

if __FILE__ == $0
    puts "========================="
    puts "Welcome to the CLI-tiempo"
    puts "========================="
    puts "> Enter a city name:"
    
    weather_check
end