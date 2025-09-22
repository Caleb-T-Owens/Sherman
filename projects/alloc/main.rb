require "securerandom"
require "json"

config = File.read("config.json", chomp: true).chomp
config = JSON.parse(config)

values = {}

config["options"].each do |key, value|
  values[key] = SecureRandom.random_number * (value["bias"] || 1)
end

total = values.values.sum

values.transform_values! { _1 / total }

total = config["amount"]

values.each do |key, value|
  puts "#{key}: #{(value * total).floor}"
end
