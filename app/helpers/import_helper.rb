module ImportHelper
  
  def fields
    return {
      :name => 'name',
      :description => 'description',
      :charge => 'charge',
      :category => 'type'
    }
  end
  
  def import_from_yaml(file_location)
    
    # convert YAML file to ruby object
    object = YAML.load_file(file_location)
    puts object.inspect
    
    requirements = Array.new
    
    object['requirements'].each do |r|
      requirements.push(extract_requirement(r, nil))
    end
    
    requirements
  end
  
  # convert the object from the yaml file to a Requirement object
  def extract_requirement(object, parent_id)
       
    # create a new Requirement object
    req = Requirement.new
    
    # set the requirement's properties
    fields.keys.each do |key|
      if (object[fields[key]])
        req[key] = object[fields[key]]
      end
    end   
    
    # set the parent of the requirement
    if parent_id
      req.requirement_id = parent_id
    end
    
    # save the requirement in the database
    req.save
    
    # do the same with all its children
    children = object['children']
    if (children)
      children.each do |child|
        extract_requirement(child, req.id)
      end     
    end

    req
  end
  
end
