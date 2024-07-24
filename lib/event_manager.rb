require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/[^\d]/, '')
  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == '1'
    phone_number[1..10]
  else
    'Wrong number!'
  end
end

def frequency(arr)
  arr.max_by { |e| arr.count(e) }
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours_of_day = []
day_of_week = []
WEEKDAYS = { 0 => 'sunday', 1 => 'monday', 2 => 'tuesday', 3 => 'wednesday', 4 => 'thursday', 5 => 'friday',
             6 => 'saturday' }

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone])
  reg_date = row[:regdate]
  date_time = DateTime.strptime(reg_date, '%m/%d/%Y %k:%M')
  hours_of_day << date_time.hour
  day_of_week << date_time.wday

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end

puts "Most active hour of the day is: #{frequency(hours_of_day)} oclock"
puts "Most active days is: #{WEEKDAYS[frequency(day_of_week)]}"
