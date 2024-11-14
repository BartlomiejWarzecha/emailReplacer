class TemplateProcessor
    def initialize(module_file_path)
      @module_file = File.read(module_file_path)
      @modules = extract_modules(@module_file)
      puts "Found modules: #{@modules.keys}"
    end
  
    def process_template(template_path)
      template = File.read(template_path)
      puts "\nProcessing template: #{template_path}"
      process_placeholders(template)
    end
  
    private
  
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
      result = processor.process_template('mail1.html')
      
      File.write('email_with_full_module_structure.html', result)
      puts "\nProcessing completed! Check email_with_full_module_structure.html"
    rescue StandardError => e
      puts "Error: #{e.message}"
    end
  end