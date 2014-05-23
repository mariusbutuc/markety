module Markety
  class Campaign

    =begin Docs
      # runs an existing Marketo lead in a Marketo Smart Campaign

      # You can send a transactional email from Marketo using
      # the requestCampaign SOAP API.
      #
      # It requires
      #  * an existing Smart Campaign to be created using the Marketo UI
      #  * the email recipient to exist in Marketo
      #
      # So before calling the requestCampaign API,
      # use the getLead API to verify if the email exists in Marketo.
      #
      # After you make a call via the requestCampaign API, you can confirm it
      # by checking to see if the Smart Campaign has run in Marketo.
    =end





  =begin Params
    # [R] leadList->leadKey->keyType
    #
    # [R] leadList->leadKey->keyValue
    #
    RequestCampaignSourceType::MKTOWS
    # [R] source
    #
    # [O] campaignId
    #   | campaignName
    #
    # [O] programName
    #   | programTokenList
    #
    # [O] programTokenList->attrib->name
    #
    # [O] programTokenList->attrib->value
    #
    # Note: Limit of 100 leadKey values per call
  =end

  =begin Rb example
    require 'savon' # Use version 2.0 Savon gem
    require 'date'

    mktowsUserId = "" # CHANGE ME
    marketoSecretKey = "" # CHANGE ME
    marketoSoapEndPoint = "" # CHANGE ME
    marketoNameSpace = "http://www.marketo.com/mktows/"

    #Create Signature
    Timestamp = DateTime.now
    requestTimestamp = Timestamp.to_s
    encryptString = requestTimestamp + mktowsUserId
    digest = OpenSSL::Digest.new('sha1')
    hashedsignature = OpenSSL::HMAC.hexdigest(digest, marketoSecretKey, encryptString)
    requestSignature = hashedsignature.to_s

    #Create SOAP Header
    headers = {
      'ns1:AuthenticationHeader' => {
        "mktowsUserId" => mktowsUserId,
        "requestSignature" => requestSignature,
        "requestTimestamp"  => requestTimestamp
      }
    }

    client = Savon.client(
      # wsdl: 'http://app.marketo.com/soap/mktows/2_3?WSDL',
      soap_header: headers,
      # endpoint: marketoSoapEndPoint,
      open_timeout: 90,
      read_timeout: 90,
      namespace_identifier: :ns1,
      # env_namespace: 'SOAP-ENV'
    )
  =end

end
