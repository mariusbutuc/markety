module Markety
  def self.new_client(access_key, secret_key, end_point, api_version = '2_3')
    client = Savon.client do
      endpoint end_point
      wsdl "http://app.marketo.com/soap/mktows/#{api_version}?WSDL"
      env_namespace "SOAP-ENV"
      namespaces({"xmlns:ns1" => "http://www.marketo.com/mktows/"})
      pretty_print_xml true
    end

    Client.new(client, Markety::AuthenticationHeader.new(access_key, secret_key))
  end

  class Client
    def initialize(savon_client, authentication_header)
      @client = savon_client
      @header = authentication_header
    end

    public

    def get_lead_by_idnum(idnum)
      get_lead(LeadKey.new(LeadKeyType::IDNUM, idnum))
    end


    def get_lead_by_email(email)
      get_lead(LeadKey.new(LeadKeyType::EMAIL, email))
    end

    # To be extracted out – Campaign#request()
    def request_campaign(options = {})
      source = get_campaign_source(options)

      leads = get_leads(options)

      identify_campaign(options)

      if (tokens = options.delete(:program_tokens)) && !tokens.empty?
        if !options[:program_name]
          raise KeyError,
            ':program_name must be provided when using :program_tokens'
        end
      end

      response = send_request(:request_campaign, {
        lead_list: leads,
        source: source,
        campaign_id: campaign_id,
      })

      response.to_hash[:success_request_campaign][:result][:success]
    end

    def get_campaign_source(options)
      options.fetch(:source, ReqCampSourceType::MKTOWS)
    end

    def get_leads(options)
      leads = options.fetch(:leads, {})

      if leads.empty?
        raise ArgumentError, ':leads must be provided'
      end

      if leads.count > 100
        raise ArgumentError, 'the API supports maximum 100 :leads per call'
      end

      # pull out leads by their identifier

      leads
    end

    def identify_campaign(options)
      valid_id =  options.include?(:campaign_id) ||
                  options.include?(:campaign_name) ||
                  options.include?(:program_name)

      unless valid_id
        raise ArgumentError,
          ':campaign_id, :campaign_name, or :program_name must be provided'
      end

      if options.include?(:campaign_id) && options.include?(:campaign_name)
        raise ArgumentError,
          ':campaign_id and :campaign_name are mutually exclusive'
      end

      # retrieve campaign
    end

    def set_logger(logger)
      @logger = logger
    end

    def sync_lead(email, first, last, company, mobile)
      lead_record = LeadRecord.new(email)
      lead_record.set_attribute('FirstName', first)
      lead_record.set_attribute('LastName', last)
      lead_record.set_attribute('Email', email)
      lead_record.set_attribute('Company', company)
      lead_record.set_attribute('MobilePhone', mobile)
      sync_lead_record(lead_record)
    end

    def sync_lead_record(lead_record)
      begin
        attributes = []
        lead_record.each_attribute_pair do |name, value|
          attributes << {attr_name: name, attr_value: value, attr_type: lead_record.get_attribute_type(name) }
        end

        response = send_request(:sync_lead, {
          return_lead: true,
          lead_record: {
            email: lead_record.email,
            lead_attribute_list: {
              attribute: attributes
            }
          }
        })

        return LeadRecord.from_hash(response[:success_sync_lead][:result][:lead_record])
      rescue Exception => e
        @logger.log(e) if @logger
        return nil
      end
    end

    def sync_lead_record_on_id(lead_record)
      idnum = lead_record.idnum
      raise 'lead record id not set' if idnum.nil?

      begin
        attributes = []
        lead_record.each_attribute_pair do |name, value|
          attributes << {attr_name: name, attr_value: value}
        end

        attributes << {attr_name: 'Id', attr_type: 'string', attr_value: idnum.to_s}

        response = send_request(:sync_lead, {
          return_lead: true,
          lead_record:
          {
            lead_attribute_list: { attribute: attributes},
            id: idnum
          }
        })
        return LeadRecord.from_hash(response[:success_sync_lead][:result][:lead_record])
      rescue Exception => e
        @logger.log(e) if @logger
        return nil
      end
    end

    def add_to_list(list_name, idnum)
      list_operation(list_name, ListOperationType::ADD_TO, idnum)
    end

    def remove_from_list(list_name, idnum)
      list_operation(list_name, ListOperationType::REMOVE_FROM, idnum)
    end

    def is_member_of_list?(list_name, idnum)
      list_operation(list_name, ListOperationType::IS_MEMBER_OF, idnum)
    end

    private
      def list_operation(list_name, list_operation_type, idnum)
        begin
          response = send_request(:list_operation, {
            list_operation: list_operation_type,
            strict:         'false',
            list_key: {
              key_type: 'MKTOLISTNAME',
              key_value: list_name
            },
            list_member_list: {
              lead_key: [{
                key_type: 'IDNUM',
                key_value: idnum
                }
              ]
            }
          }
        )
        return response
      rescue Exception => e
        @logger.log(e) if @logger
        return nil
      end
    end

    def get_lead(lead_key)
      begin
        response = send_request(:get_lead, {"leadKey" => lead_key.to_hash})
        return LeadRecord.from_hash(response[:success_get_lead][:result][:lead_record_list][:lead_record])
      rescue Exception => e
        @logger.log(e) if @logger
        return nil
      end
    end

    def send_request(namespace, message)
      @header.set_time(DateTime.now)
      response = request(namespace, message, @header.to_hash)
      response.to_hash
    end

    def request(namespace, message, header)
      @client.call(namespace, message: message, soap_header: header)
    end
  end
end
