require 'json'
require 'net/http'
require 'uri'
require 'securerandom'
require 'fileutils'

class EmailApiManager
  def initialize(config)
    @config = {
      client_id: config[:client_id],
      api_key: config[:api_key],
      base_url: config[:base_url],
      sender_account_id: config[:sender_account_id],
      email_owner: config[:email_owner]
    }
    validate_config
  end

  def upsert_email(file_path)
    email_id = extract_email_id(file_path)
    content = File.read(file_path)
    
    request_body = {
      clientId: @config[:client_id],
      apiKey: @config[:api_key],
      requestTime: current_timestamp,
      sha: generate_sha,
      emailId: email_id,
      emailOwner: @config[:email_owner],
      name: "Email Template #{email_id}",
      subject: "Test Email Subject",
      senderAccountId: @config[:sender_account_id],
      content: content,
      shared: false,
      utmCampaign: "Test Campaign"
    }

    send_api_request('/api/email/upsert', request_body)
  end

  
  def send_test_email(email_id, test_emails)
    request_body = {
      clientId: @config[:client_id],
      apiKey: @config[:api_key],
      requestTime: current_timestamp,
      sha: generate_sha,
      emailId: email_id,
      contacts: [
        {
          addresseeType: "EMAIL",
          value: test_emails.join(", ")
        }
      ]
    }

    send_api_request('/api/email/send', request_body)
  end

  def process_future_emails
    dir_path = 'future_email_end'
    puts "Processing emails from: #{dir_path}"

    Dir.glob("#{dir_path}/*.html").each do |file_path|
      begin
        puts "\nProcessing: #{file_path}"
        response = upsert_email(file_path)
        
        if response['success']
          email_id = extract_email_id(file_path)
          move_to_processed(file_path)
          puts "Successfully processed: #{email_id}"
        else
          puts "Failed to process: #{file_path}"
        end
      rescue StandardError => e
        puts "Error processing #{file_path}: #{e.message}"
      end
    end
  end

  private

  def validate_config
    required_fields = [:client_id, :api_key, :base_url, :sender_account_id, :email_owner]
    missing = required_fields.select { |field| @config[field].nil? || @config[field].empty? }
    raise "Missing required config: #{missing.join(', ')}" if missing.any?
  end

  def extract_email_id(file_path)
    File.basename(file_path).split('_')[1]&.split('.')[0] 
  end

  def current_timestamp
    (Time.now.to_f * 1000).to_i
  end

  def generate_sha
    SecureRandom.hex(20)
  end

  def send_api_request(endpoint, body)
    uri = URI.parse("#{@config[:base_url]}#{endpoint}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'
    request.body = body.to_json

    response = http.request(request)
    handle_response(response)
  end

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)
    else
      raise "API request failed: #{response.code} - #{response.message}\n#{response.body}"
    end
  end

  def move_to_processed(file_path)
    processed_dir = 'processed_emails'
    FileUtils.mkdir_p(processed_dir)
    FileUtils.mv(file_path, "#{processed_dir}/#{File.basename(file_path)}")
  end
end


if __FILE__ == $0
  begin
    require 'dotenv'
    Dotenv.load

    config = {
      client_id: ENV['API_CLIENT_ID'],
      api_key: ENV['API_KEY'],
      base_url: ENV['API_BASE_URL'],
      sender_account_id: ENV['SENDER_ACCOUNT_ID'],
      email_owner: ENV['EMAIL_OWNER']
    }


    manager = EmailApiManager.new(config)

    manager.process_future_emails

  
    test_emails = ['test1@example.com', 'test2@example.com']
    processed_dir = 'processed_emails'
    Dir.glob("#{processed_dir}/*.html").each do |file_path|
      email_id = manager.extract_email_id(file_path)
      manager.send_test_email(email_id, test_emails)
      puts "Sent test email for: #{email_id}"
    end

  rescue StandardError => e
    puts "Error: #{e.message}"
    puts e.backtrace
  end
end