class TemplateDataIntegrator
    def initialize(nested_modules_path)
      @nested_modules = File.read(nested_modules_path)
      @module_data = extract_module_data(@nested_modules)
      puts "Found nested modules: #{@module_data.keys}"
    end
  
    def fill_template(template_path)
      template = File.read(template_path)
      puts "\nFilling template with nested module data..."
      result = process_data_placeholders(template)
      
      # Save final result
      File.write('final_template.html', result)
      puts "Template filled and saved to: final_template.html"
      
      result
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
      integrator.fill_template('email_with_full_module_structure.html')
      puts "\nProcessing completed!"
    rescue StandardError => e
      puts "Error: #{e.message}"
    end
  end