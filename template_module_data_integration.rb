class TemplateDataIntegrator
    def initialize(nested_modules_path)
      @nested_modules = File.read(nested_modules_path)
      @module_data = extract_module_data(@nested_modules)
      puts "Found nested modules: #{@module_data.keys}"
    end

            
    def process_templates
        # Create future_emails directory if it doesn't exist
        Dir.mkdir('future_emails_end') unless Dir.exist?('future_emails_end')
            
        # Process all HTML files in current_emails directory
        Dir.glob('future_emails_schema/*.html') do |email_file|
        process_single_template(email_file)
        end
    end

    def process_single_template(email_path)
        template = File.read(email_path)
        filename = File.basename(email_path)
        puts "\nProcessing template: #{filename}"
    
        has_changes = false
        result = process_data_placeholders(template)
    
    if template != result
      has_changes = true
      output_path = File.join('future_emails_end', filename)
      File.write(output_path, result)
      puts "Changes detected - Saved to: #{output_path}"
    else
      puts "No changes needed for: #{filename}"
    end
    
    has_changes
  end

    private
  
    def process_data_placeholders(content)
      result = content.dup
      
      # Track which modules have been processed
      processed_modules = Set.new
      
      @module_data.each do |name, data_content|
        next if processed_modules.include?(name)
        
        start_tag = "<!-- #{name}_START -->"
        end_tag = "<!-- #{name}_END -->"
        
        if result.include?(start_tag) && result.include?(end_tag)
          puts "Filling nested module: #{name}"
          start_index = result.index(start_tag) + start_tag.length
          end_index = result.index(end_tag)
          
          # Replace content
          result = result[0...start_index] + "\n#{data_content}\n" + result[end_index..]
          processed_modules.add(name)
          puts "Filled content for: #{name}"
        end
      end
      
      result
    end
  
    def extract_module_data(content)
      data_modules = {}
      content.scan(/<!-- (.+?)_START -->\s*(.*?)\s*<!-- \1_END -->/m) do |name, module_content|
        data_modules[name] = module_content.strip
        puts "Extracted nested module: #{name}"
      end
      data_modules
    end
  end
  
  # Run the integrator
  if __FILE__ == $0
    begin
      puts "Starting nested module integration..."
      integrator = TemplateDataIntegrator.new('nested_modules.html')
      integrator.process_templates
      puts "\nProcessing completed!"
    rescue StandardError => e
      puts "Error: #{e.message}"
    end
  end