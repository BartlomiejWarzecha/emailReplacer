require_relative 'template_processor'
require_relative 'template_module_data_integration'

class EmailTemplateBuilder
  def self.build(template_file, module_file, data_file)
    puts "=== Starting Email Template Building Process ==="
    
    # Step 1: Process module structure
    puts "\n1. Processing module structure..."
    processor = TemplateProcessor.new(module_file)
    intermediate_result = processor.process_template(template_file)
    
    # Save intermediate result
    File.write('intermediate_template.html', intermediate_result)
    puts "Module structure processed!"
    
    # Step 2: Fill in data
    puts "\n2. Filling in module data..."
    integrator = TemplateDataIntegrator.new(data_file)
    final_result = integrator.fill_template('intermediate_template.html')
    
    # Save final result
    File.write('final_template.html', final_result)
    puts "\n=== Template building completed! ==="
    puts "Final template saved to: final_template.html"
    
    final_result
  end
end

# Run the builder
if __FILE__ == $0
  begin
    EmailTemplateBuilder.build(
      'mail2.html',      # Template file
      'module-file.html', # Module structure file
      'nested_modules.html' # Module data file
    )
  rescue StandardError => e
    puts "\nError: #{e.message}"
    puts e.backtrace
  end
end 