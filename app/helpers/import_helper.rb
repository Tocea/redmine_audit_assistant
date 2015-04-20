module ImportHelper
  
  def fields # mapping requirement properties => yaml properties found
    {
      :name => 'name',
      :description => 'description',
      :charge => 'charge',
      :category => 'type',
      :start_date => 'start_date',
      :effective_date => 'effective_date',
      :assignee_login => 'assignee',
      :priority_id => 'priority'
    }
  end
  
  def version_fields # mapping version properties => yaml properties found
    {
      :name => 'name',
      :description => 'description',
      :effective_date => 'date'
    }
  end
  
  def import_from_yaml(file_location)
    
    # convert YAML file to ruby object
    object = YAML.load_file(file_location)
    puts object.inspect
    
    # extract version data
    version = nil
    if object['version']
      version = extract_version(object['version'])      
    end
    
    # extract requirements data
    requirements = Array.new  
    object['requirements'].each do |r|
      requirements.push(extract_requirement(r, nil))
    end
    
    # return data
    {
      :requirements => requirements,
      :version => version
    }
  end
  
  # convert the object from the yaml file to a Requirement object
  def extract_requirement(object, parent_id)
       
    # create a new Requirement object
    req = Requirement.new
    
    # set the requirement's properties
    assign_fields(req, object, fields) 
    
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
  
  def extract_version(object)
    
    # create a new version
    version = Version.new
    
    # set the version's properties
    assign_fields(version, object, version_fields)
    
    # date conversion
    if version.effective_date
      version.effective_date = version.effective_date.to_date
    end
    
    version   
  end  
  
  def assign_fields(object, source, mapper)
    
    mapper.keys.each do |key|
      
      if (source[mapper[key]])
        
        # extract the value of the property from the YAML file
        value = source[mapper[key]]
        
        # get the type of the property      
        if object.column_for_attribute(key)
          type = object.column_for_attribute(key).type
        end
        
        # type conversions
        if (type && type.to_s == 'date')
          value = value.to_date
        end
        
        # assign the value to the object property
        object[key] = value
        
      end
    end
    
    object
  end  
  
end
