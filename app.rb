class CelebritySpotting < Sinatra::Base
  def to_sentence(array)
    return array.to_s if array.length <= 1
    "#{array[0..-2].join(", ")} and #{array[-1]}"
  end  

  post "/messages" do
    content_type = "text/xml"
    twiml = Twilio::TwiML::MessagingResponse.new
    if params["NumMedia"].to_i > 0
      tempfile = Down.download(params["MediaUrl0"])
      begin  
        client = Aws::Rekognition::Client.new
        response = client.recognize_celebrities image: { bytes: tempfile.read }
        if response.celebrity_faces.any?
          if response.celebrity_faces.count == 1
            celebrity = response.celebrity_faces.first
            twiml.message body: "Ooh, I am #{celebrity.match_confidence}% confident this looks like #{celebrity.name}."
          else
            twiml.message body: "I found #{response.celebrity_faces.count} celebrities in this picture. Looks like #{to_sentence(response.celebrity_faces.map { |face| face.name }) } are in the picture."
          end
        else
          case response.unrecognized_faces.count
          when 0
            twiml.message body: "I couldn't find any faces in that picture. Maybe try another pic?"
          when 1
            twiml.message body: "I found 1 face in that picture, but it didn't look like any celebrity I'm afraid."
          else
            twiml.message body: "I found #{response.unrecognized_faces.count} faces in that picture, but none of them look like celebrities."
          end
        end
      ensure
        tempfile.close!
      end
    else
      twiml.message body: "I can't look for celebrities if you don't send me a picture!"
    end
    twiml.to_xml
  end
end