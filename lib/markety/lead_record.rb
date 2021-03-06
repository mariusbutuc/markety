module Markety
  # Represents a record of the data known about a lead within marketo
  class LeadRecord
    attr_reader :types

    def initialize(email, idnum = nil)
      @idnum      = idnum
      @attributes = {}
      @types      = {}
      set_attribute('Email', email)
    end

    # hydrates an instance from a savon hash returned form the marketo API
    def self.from_hash(savon_hash)
      lead_record = LeadRecord.new(savon_hash[:email], savon_hash[:id].to_i)
      
      unless savon_hash[:lead_attribute_list].nil?
        if savon_hash[:lead_attribute_list][:attribute].kind_of? Hash
          attributes = [savon_hash[:lead_attribute_list][:attribute]]
        else
          attributes = savon_hash[:lead_attribute_list][:attribute]
        end
        
        attributes.each do |attribute|
          lead_record.set_attribute(attribute[:attr_name], attribute[:attr_value], attribute[:attr_type])
        end
      end
      
      lead_record
    end

    # get the record idnum
    def idnum
      @idnum
    end

    # get the record email
    def email
      get_attribute('Email')
    end

    def attributes
      @attributes
    end

    # update the value of the named attribute
    def set_attribute(name, value, type = "string")
      @attributes[name] = value
      @types[name] = type
    end

    # get the value for the named attribute
    def get_attribute(name)
      @attributes[name]
    end

    def get_attribute_type(name)
      @types[name]
    end

    # will yield pairs of |attribute_name, attribute_value|
    def each_attribute_pair(&block)
      @attributes.each_pair do |name, value|
        block.call(name, value)
      end
    end

    def ==(other)
      @attributes == other.attributes &&
      @idnum == other.idnum
    end
  end
end
