class TemplateProcessor
    def initialize(module_file_path)
      @module_file = File.read(module_file_path)
      @modules = extract_modules(@module_file)
      puts "Found modules: #{@modules.keys}"
    end
  
    def process_templates
        Dir.mkdir('future_emails_schema') unless Dir.exist?('future_emails_schema')
        
        Dir.glob('current_emails/*.html') do |email_file|
          process_single_template(email_file)
        end
      end
  
    private
  

    def process_single_template(email_path)
        template = File.read(email_path)
        filename = File.basename(email_path)
        puts "\nProcessing template: #{filename}"
    
        # Check if template contains any of our modules
        has_changes = false
        result = process_placeholders(template)
    
        # Compare original with processed version
        if template != result
        has_changes = true
        # Save to future_emails if changes were made
        output_path = File.join('future_emails_schema', filename)
        File.write(output_path, result)
        puts "Changes detected - Saved to: #{output_path}"
        else
        puts "No changes needed for: #{filename}"
        end
    
        has_changes
    end

    def process_placeholders(content)
      result = content.dup
      
      @modules.each do |name, module_content|
        puts "Processing module: #{name}"
        start_tag = "<!-- #{name}_START -->"
        end_tag = "<!-- #{name}_END -->"
        
        if result.include?(start_tag) && result.include?(end_tag)
          puts "Found placeholder for: #{name}"
          start_index = result.index(start_tag) + start_tag.length
          end_index = result.index(end_tag)
          result = result[0...start_index] + "\n#{module_content}\n" + result[end_index..]
        end
      end
      
      result
    end
  
    def extract_modules(content)
      modules = {}
      content.scan(/<!-- (.+?)_START -->\s*(.*?)\s*<!-- \1_END -->/m) do |name, module_content|
        modules[name] = module_content.strip
        puts "Extracted module: #{name}"
      end
      modules
    end
  end
  
  # Run the processor
  if __FILE__ == $0
    begin
      processor = TemplateProcessor.new('module_file.html')
      result = processor.process_templates
      
      File.write('email_with_full_module_structure.html', result)
      puts "\nProcessing completed! Check email_with_full_module_structure.html"
    rescue StandardError => e
      puts "Error: #{e.message}"
    end
  end