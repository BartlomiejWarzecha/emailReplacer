class TemplateDataIntegrator
    def initialize(data_file_path)
      @data_file = File.read(data_file_path)
      @module_data = extract_module_data(@data_file)
      puts "Found data modules: #{@module_data.keys}"
    end
  
    def fill_template(template_path)
      template = File.read(template_path)
      puts "Filling template with data..."
      process_data_placeholders(template)
    end
  
    private
  
    def process_data_placeholders(content)
      result = content.dup
      changed = true
      
      while changed
        changed = false
        @module_data.each do |name, data_content|
          start_tag = "<!-- #{name}_START -->"
          end_tag = "<!-- #{name}_END -->"
          
          if result.include?(start_tag) && result.include?(end_tag)
            start_index = result.index(start_tag) + start_tag.length
            end_index = result.index(end_tag)
            current_content = result[start_index...end_index]
            
            if current_content.strip != data_content.strip
              result = result[0...start_index] + "\n#{data_content}\n" + result[end_index..]
              changed = true
              puts "Filled data for: #{name}"
            end
          end
        end
      end
      
      result
    end
  
    def extract_module_data(content)
      data_modules = {}
      content.scan(/<!-- (.+?)_START -->\s*(.*?)\s*<!-- \1_END -->/m) do |name, module_content|
        data_modules[name] = module_content.strip
        puts "Extracted data module: #{name}"
      end
      data_modules
    end
  end