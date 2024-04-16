class MessagesController < ApplicationController
  def index
    message = {:author => "rudimk", :text => "In rememberance of Earth's past."}
    render json: message.to_json
  end
end
